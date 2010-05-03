package = "lua-phpserialize"
version = "0.0.2-1"

source = {
   url = "http://github.com/agladysh/lua-phpserialize/tarball/v0.0.2",
}

description = {
   summary = "Lua module to support PHP serialize()",
   detailed = [[
      lua-phpserialize: A module to work with PHP serialize() format.
   ]],
   homepage = "http://github.com/agladysh/lua-phpserialize",
   license = "MIT/X11"
}

dependencies = {
   "lua >= 5.1"
}

build = {
   type = "builtin",
   modules = {
      phpserialize = {
         sources = {
            "src/lua-phpserialize.c",
            "src/util.c"
         },
         incdirs = {
            "src/"
         }
      }
   }
}
