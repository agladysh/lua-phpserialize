lua-phpserialize: A library to work with PHP serialize() format
===============================================================

phpserialize.phpserialize()
---------------------------

`phpserialize.phpserialize(value, [php_base_index]) : string or nil, err`

Parameters:

 * `value`: value to be serialized
 * `php_base_index`: base index for resulting PHP arrays (if any).
   Optional, default: 1.

Serializes primitive Lua values (including tables) to format,
understandable by PHP's `unserialize()` function.

Returns string with serialized data or `nil` and error message.

Serializable Lua types with PHP counterparts:

  `nil` => `null`
  `boolean` => `bool`
  `number` (integers) => `integer`
  `number` (non-integers, except `-NaN`, `-inf`, `+inf`) => `double`
  `table` => `array` (but see below)

Non-serializable Lua types:

  `function` (would fail)
  `coroutine` (would fail)
  `userdata` / `lightuserdata` (would fail)
  numbers `NaN`, `-inf`, `+inf` (would fail)

Serializable table key types:

  `number` (integers only!) => `integer`
  `string` (not representing integers only!) => `string`

Any other key type (including non-integer numbers and
strings, convertible to integers, see below) would fail.

Table value may be of any of serializable Lua types (see above).

Notes on serialization of tables:
---------------------------------

This function does NOT handle fancy stuff like metatables (ignored),
weak table keys/values (treated as normal) and recursive tables
(would fail). Non-recursive tables deeper that `PHPSERIALIZE_MAXNESTING`
(default 128) are also can't be serialized.

Due to limitations of PHP's array type, table keys may be strings
or integers only. PHP forbids string keys convertible to integers --
such keys are automatically converted to integers at array creation.
To force unambigous serialization, non-integer numeric keys and
string keys, convertible to integers are forbidden.

Note that it is not possible in Lua to have `nil` as table key.

See the copyright information in the file named `COPYRIGHT`.
