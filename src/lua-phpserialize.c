/*
* lphpserialize.c: Lua support for PHP serialize()
* This file is a part of lua-phpserialize library.
* Copyright (c) lua-phpserialize authors (see file `COPYRIGHT` for the license)
*/

#include "lua.h"
#include "lauxlib.h"

#include "util.h"

/* TODO: Write non-recursive implementation */
#define PHPSERIALIZE_MAXNESTING (128) /* Maximum Lua table nesting phpserialize() can handle */
#define PHPSERIALIZE_FLOATPRECISION_STR "55" /* Default value in PHP for float serialization */

#ifndef PHPSERIALIZE_64BIT
/* Bigger keys causing issues in PHP (at least in 5.2.6-2ubuntu4) */
/* Values are not exact (from higher digits) */
#define PHPSERIALIZE_MAXARRAYINTKEY ( 2110000001)
#define PHPSERIALIZE_MINARRAYINTKEY (-2140000001)
#else
#error "TODO: Find MIN/MAX values for 64bit platforms";
#endif

/* Arbitrary number of used stack slots to trigger preliminary concatenation */
/* TODO: Should be dependent on LUAI_MAXCSTACK? */
#define PHPSERIALIZE_CONCATTHRESHOLD (1024)


enum SerializeStringID
{
  SSI_NULL          = 1,
  SSI_INTEGER       = 2,
  SSI_DOUBLE        = 3,
  SSI_BOOL_TRUE     = 4,
  SSI_BOOL_FALSE    = 5,
  SSI_STRING_BEGIN  = 6,
  SSI_STRING_MIDDLE = 7,
  SSI_STRING_END    = 8,
  SSI_ARRAY_BEGIN   = 9,
  SSI_ARRAY_MIDDLE  = 10,
  SSI_ARRAY_END     = 11,
  SSI_SEMICOLON     = 12,

  NUM_SSI           = 12 /* Note IDs are one-based */
};

const char * const g_SerializeStrings[NUM_SSI + 1] =
{
  "",     /* Placeholder to be one-based */
  "N;",   /* SSI_NULL */
  "i:",   /* SSI_INTEGER */
  "d:",   /* SSI_DOUBLE */
  "b:1;", /* SSI_BOOL_TRUE */
  "b:0;", /* SSI_BOOL_FALSE */
  "s:",   /* SSI_STRING_BEGIN */
  ":\"",  /* SSI_STRING_MIDDLE */
  "\";",  /* SSI_STRING_END */
  "a:",   /* SSI_ARRAY_BEGIN */
  ":{",   /* SSI_ARRAY_MIDDLE */
  "}",    /* SSI_ARRAY_END */
  ";"     /* SSI_SEMICOLON */
};

/* phpserialize
 * ============
 *
 * Serializes primitive Lua values (including tables) to format,
 * understandable by PHP's unserialize() function.
 *
 * Returns string with serialized data or nil and error message.
 *
 * Serializable Lua types with PHP counterparts:
 *
 *   nil => null
 *   boolean => bool
 *   number (integers) => integer
 *   number (non-integers, except -NaN, -inf, +inf) => double
 *   table => array (but see below)
 *
 * Non-serializable Lua types:
 *
 *   function (would fail)
 *   coroutine (would fail)
 *   userdata/lightuserdata (would fail)
 *   numbers NaN, -inf, +inf (would fail)
 *
 * Serializable table key types:
 *
 *   number (integers only!) => integer
 *   string (not representing integers only!) => string
 *
 * Any other key type (including non-integer numbers and
 * strings, convertible to integers, see below) would fail.
 *
 * Array part of table is serialized as Lua-native 1-based.
 * No attempt is made to convert it to PHP-native 0-based.
 *
 * Table value may be of any of serializable Lua types (see above).
 *
 * Notes on serialization of tables:
 * ---------------------------------
 *
 * This function does NOT handle fancy stuff like metatables (ignored),
 * weak table keys/values (treated as normal) and recursive tables
 * (would fail). Non-recursive tables deeper that PHPSERIALIZE_MAXNESTING
 * (default 128) are also can't be serialized.
 *
 * Due to limitations of PHP's array type, table keys may be strings
 * or integers only. PHP forbids string keys convertible to integers --
 * such keys are automatically converted to integers at array creation.
 * To force unambigous serialization, non-integer numeric keys and
 * string keys, convertible to integers are forbidden.
 *
 * Note that it is not possible in Lua to have nil as table key.
 */

/* If retain is 1, retains the top element on stack (slow) */
static void maybe_concat(lua_State * L, int base, int retain)
{
  int top = lua_gettop(L);
  if (top - base >= PHPSERIALIZE_CONCATTHRESHOLD)
  {
    if (retain)
    {
      lua_insert(L, base);
    }

    lua_concat(L, top - base);

    if (retain)
    {
      /* swap result with retained element */
      lua_pushvalue(L, -2);
      lua_remove(L, -3);
    }
  }
}

/* Returns 0 if string looks like integer */
static int Plookslikeinteger(const char * str, const size_t len)
{
  /* TODO: Looks like we would have problems with unicode here */
  int notguilty = 0;
  size_t i = 0;
  if (len > 1 && str[0] == '0') /* PHP does not honor string integer keys with leading zeroes as integers */
  {
    notguilty = 1;
  }
  else
  {
    for (i = 0; i < len; ++i)
    {
      if (str[i] < '0' || str[i] > '9')
      {
        notguilty = 1;
        break;
      }
    }
  }

  return notguilty;
}

/*
 * Warning: Index must be absolute! For example, you must use lua_gettop() instead of -1.
 * Note: Upvalues referenced here are belong to Cphpserialize function below.
 * Note: This function does not clean up stack after itself
 */
static int Pphpserializekey(lua_State * L, int index, int php_base_index)
{
  int type = lua_type(L, index);
  int error = 0;

  luaL_checkstack(L, 5, "serializekey"); /* Arbitrary value */

  switch (type)
  {
  case LUA_TNUMBER:
    {
      /* TODO: Ensure this is correct check for number being integer. Check corner cases (math.huge, NaN, epsilon, etc.)! */
      /* TODO: Filter out NaN, -inf, +inf etc. */
      lua_Number number = lua_tonumber(L, index);
      if (number != (lua_Integer)number || !is_float_finite(number) )
      {
        lua_pushnil(L);
        lua_pushfstring(L, "non-integer numeric keys are not supported");
        error = 1;
      }
      else if (number > PHPSERIALIZE_MAXARRAYINTKEY || number < PHPSERIALIZE_MINARRAYINTKEY)
      {
        lua_pushnil(L);
        lua_pushfstring(L, "integer key too big/too small");
        error = 1;
      }
      else
      {
        char big_integer[256] = {0};

        lua_Integer number = lua_tointeger(L, index);
        number = number + (php_base_index - 1);
        lua_pushvalue(L, lua_upvalueindex(SSI_INTEGER));

        /* instead of using lua`s tostring we make conversion by hand. This will overcome 10000... -> 1e14 issue */
        /* was: lua_pushinteger(L, number);lua_tostring(L, -1);*/
        /*snprintf(big_integer, sizeof(big_integer), "%d", number); // We can not use this method in c89 */
        sprintf(big_integer, "%d", (int)number);
        lua_pushstring(L, big_integer);
        lua_pushvalue(L, lua_upvalueindex(SSI_SEMICOLON));
      }
    }
    break;

  case LUA_TSTRING:
    {
      size_t len = 0;
      const char * str = lua_tolstring(L, index, &len);
      if (Plookslikeinteger(str, len) == 0)
      {
        lua_pushnil(L);
        lua_pushfstring(L, "string keys convertible to integers are not supported");
        error = 1;
      }
      else
      {
        lua_pushvalue(L, lua_upvalueindex(SSI_STRING_BEGIN));
        lua_pushinteger(L, len);
        lua_tostring(L, -1);
        lua_pushvalue(L, lua_upvalueindex(SSI_STRING_MIDDLE));
        lua_pushvalue(L, index); /* Note that the string need not to be escaped. */
        lua_pushvalue(L, lua_upvalueindex(SSI_STRING_END));
      }
    }
    break;

  case LUA_TNIL:
  case LUA_TNONE:
  case LUA_TBOOLEAN:
  case LUA_TTABLE:
  case LUA_TFUNCTION:
  case LUA_TUSERDATA:
  case LUA_TTHREAD:
  case LUA_TLIGHTUSERDATA:
  default:
    lua_pushnil(L);
    lua_pushfstring(L, "unsupported key type `%s'", lua_typename(L, type));
    error = 1;
    break;
  }

  return error;
}

/*
 * Warning: Index must be absolute! For example, you must use lua_gettop() instead of -1.
 * Note: Upvalues referenced here are belong to Cphpserialize function below.
 */
static int Pphpserializevalue(lua_State * L, int index, int php_base_index, int nesting)
{
  int type = LUA_TNONE;
  int error = 0;

  LCALL(L, stack);

  do
  {
    if (nesting > PHPSERIALIZE_MAXNESTING)
    {
      lua_pushnil(L);
      lua_pushliteral(L, "too deep");
      error = 1;
      break;
    }

    luaL_checkstack(L, 10, "serializevalue"); /* Arbitrary value */

    type = lua_type(L, index);
    switch (type)
    {
    case LUA_TNIL:
    case LUA_TNONE:
      lua_pushvalue(L, lua_upvalueindex(SSI_NULL));
      break;

    case LUA_TNUMBER:
      {
        char big_integer[256] = {0};
        /* TODO: Ensure this is correct check for number being integer. Check corner cases (math.huge, NaN, epsilon, etc.)! */
        lua_Number number = lua_tonumber(L, index);
        if (!is_float_finite(number) )
        {
          lua_pushnil(L);
          lua_pushfstring(L, "NaN/Infinte values are not supported");
          error = 1;
        }
        if (error == 0)
        {
          /* instead of using Lua`s tostring we make conversion by hand. This will overcome 10000... -> 1e14 issue */
          /* was: lua_pushinteger(L, number);lua_tostring(L, -1);*/
          if (number != (lua_Integer)number)
          {
            /*snprintf(big_integer, sizeof(big_integer), "%#." PHPSERIALIZE_FLOATPRECISION_STR "f", number); // We can not use this method in c89 */
            sprintf(big_integer, "%#." PHPSERIALIZE_FLOATPRECISION_STR "f", number);
            lua_pushvalue(L, lua_upvalueindex(SSI_DOUBLE));
          }
          else
          {
            lua_Integer number_int = (lua_Integer)lua_tonumber(L, index);
            /*snprintf(big_integer, sizeof(big_integer), "%d", number_int); // We can not use this method in c89 */
            sprintf(big_integer, "%d", (int)number_int);
            lua_pushvalue(L, lua_upvalueindex(SSI_INTEGER));
          }
          lua_pushstring(L, big_integer);
          lua_pushvalue(L, lua_upvalueindex(SSI_SEMICOLON));
        }
      }
      break;

    case LUA_TBOOLEAN:
      lua_pushvalue(L, lua_upvalueindex((lua_toboolean(L, index) == 1) ? SSI_BOOL_TRUE : SSI_BOOL_FALSE));
      break;

    case LUA_TSTRING:
      lua_pushvalue(L, lua_upvalueindex(SSI_STRING_BEGIN));
      lua_pushinteger(L, lua_objlen(L, index));
      lua_tostring(L, -1);
      lua_pushvalue(L, lua_upvalueindex(SSI_STRING_MIDDLE));
      lua_pushvalue(L, index); /* Note that the string need not to be escaped. */
      lua_pushvalue(L, lua_upvalueindex(SSI_STRING_END));
      break;

    case LUA_TTABLE:
      {
        int size = 0;
        int sizePos = 0;
        int base_table_pos = lua_gettop(L);
        lua_pushvalue(L, lua_upvalueindex(SSI_ARRAY_BEGIN));
        lua_pushnil(L); /* Size placeholder */
        sizePos = lua_gettop(L);
        lua_pushvalue(L, lua_upvalueindex(SSI_ARRAY_MIDDLE));

        lua_pushnil(L);  /* First key */
        while (error == 0 && lua_next(L, index) != 0)
        {
          int valuePos = lua_gettop(L);
          int keyPos = valuePos - 1;
          error = Pphpserializekey(L, keyPos, php_base_index);

          if (error == 0)
          {
            error = Pphpserializevalue(L, valuePos, php_base_index, nesting + 1);
            lua_remove(L, valuePos);
          }

          if (error == 0)
          {
            ++size;

            /* Move key to front of stack */
            lua_pushvalue(L, keyPos);
            lua_remove(L, keyPos);
          }
        }

        if (error == 0)
        {
          lua_pushvalue(L, lua_upvalueindex(SSI_ARRAY_END));
          lua_pushinteger(L, size);
          lua_tostring(L, -1);
          lua_replace(L, sizePos);

          maybe_concat(L, base_table_pos + 1, 1);
        }
      }
      break;

    case LUA_TFUNCTION:
    case LUA_TUSERDATA:
    case LUA_TTHREAD:
    case LUA_TLIGHTUSERDATA:
    default:
      lua_pushnil(L);
      lua_pushfstring(L, "unsupported value type `%s'", lua_typename(L, type));
      error = 1;
      break;
    }
  } while (0);

  if (error != 0)
  {
    if (LEXTRA(L, stack) < 2)
    {
      return luaL_error(L, "implementation error: missing error message");
    }

    luaL_checkstack(L, 2, "serializevalue");

    /* Clean up stack, leaving only nil and error message */
    lua_insert(L, LBASE(L, stack) + 1);
    lua_insert(L, LBASE(L, stack) + 1);

    lua_pop(L, LEXTRA(L, stack) - 2);
  }

  return error;
}

static int Cphpserialize(lua_State * L)
{
  int success = 0;
  LCALL(L, stack);

  int php_base_index = luaL_optint(L, 2, 1);
  success = (Pphpserializevalue(L, 1, php_base_index, 0) == 0);

  if (!success)
  {
    LRET(L, stack, 2); /* Nil with error message */
  }

  /* Warning: This would attempt to concat *all* values added on stack since this function called.
   *          Beware of stack balancing errors! Ensure only string values are left in stack.
   */
  lua_concat(L, LEXTRA(L, stack));

  LRET(L, stack, 1);
}

/*
 * Usage example:
 *
 *
 * TODO:
 *
 * -- phpunserialize
 * -- var_export-like serialization (to PHP code, not to unserializeable string)
 * -- maximum tolerance version, which attempts to serialize as much as ever possible,
 *    converts non-integer numeric keys to strings, integer string keys to integers etc.
 *
 * -- NaN, math.huge, epsilon tests
 * -- Self save-load cycle tests
 * -- os.exec("php -r") tests (both by load-unload and by serialized string comparsion)
 * -- also look at php own serialize/unserialize tests, and borrow test data from there.
 * -- test large (>BUFSIZ) amounts of data (both as solid strings and as a lot of small objects)
 * -- fit code in 80 chars line width
 * -- add support for table recusrion/references (R:...)
 * -- Use own auto-growing char buffer instead of Lua stack on save.
 *
 * -- Remove debugging stuff from public version
 * -- Collapse data in stack if its size is close to LUAI_MAXCSTACK
 * -- In unserialize() validate string/table sizes (see luabins)
 *
 */

#ifdef __cplusplus
extern "C"
{
#endif

LUALIB_API int luaopen_phpserialize(lua_State * L)
{
  int i = 0;

  LCALL(L, stack);

  lua_newtable(L);

  luaL_checkstack(L, NUM_SSI, "luaopen_phpserialize");
  for (i = 1; i <= NUM_SSI; ++i) /* Note string array is one-based */
  {
    lua_pushstring(L, g_SerializeStrings[i]);
  }

  lua_pushcclosure(L, Cphpserialize, NUM_SSI);
  lua_setfield(L, -2, "phpserialize");

  LRET(L, stack, 1);
}

#ifdef __cplusplus
}
#endif
