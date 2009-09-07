/*
* util.h: Utility functions.
* This file is a part of lua-phpserialize library.
* Copyright (c) lua-phpserialize authors (see file `COPYRIGHT` for the license)
*/

#ifndef UTIL_H_
#define UTIL_H_

#if defined(__WIN32__) || defined(WIN32) || defined(_WIN32)
#  define PLATFORM_WIN32
#else
#  define PLATFORM_LINUX
#  if defined(__APPLE__)
#    define PLATFORM_OSX
#  endif
#endif

#include <stdio.h>
#include <stdarg.h>

#if defined(PLATFORM_LINUX)

/* There is no finit in c89, so we using this define ti fix c89-conformance warning and isfinit*/
#ifndef __USE_MISC
#define __USE_MISC
#endif
#include <math.h>
#define is_float_finite finite

#elif defined(PLATFORM_WIN32)

#include <float.h>
#define is_float_finite _finite
#define snprintf _snprintf

#endif

int Pdumpstack(lua_State * L, int base);

#define LCALL(L, v) int v = lua_gettop(L);

#define LCHECK(L, v, n) \
  if (lua_gettop(L) != (v) + (n)) \
  { \
    Pdumpstack(L, (v)); \
    return luaL_error( \
        L, "%s(%d): unbalanced implementation (base: %d, top: %d, expected %d)", \
        __FILE__, __LINE__, (v), lua_gettop(L), (v) + (n) \
      ); \
  }

#define LRET(L, v, n) LCHECK(L, v, n); return (n);
#define LBASE(L, v) (v)
#define LTOP(L, v) (lua_gettop(L))
#define LEXTRA(L, v) (LTOP(L, v) - LBASE(L, v))

#endif
