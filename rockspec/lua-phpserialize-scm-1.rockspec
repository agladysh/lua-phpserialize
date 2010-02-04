package = "lua-phpserialize"
version = "scm-1"

source = {
   url = "git://github.com/agladysh/lua-phpserialize.git"
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
