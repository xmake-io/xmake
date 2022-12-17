#!/bin/sh

set_project "xmake"
set_version "2.7.3" "%Y%m%d%H%M"

# set warning all
set_warnings "all"

# set language: c99
set_languages "c99"

# add defines
add_defines "_GNU_SOURCE=1"  "_FILE_OFFSET_BITS=64"  "_LARGEFILE_SOURCE"

# disable some compiler errors
if is_plat "macosx"; then
    add_cxflags "-Wno-error=deprecated-declarations" "-fno-strict-aliasing" "-Wno-error=nullability-completeness" "-Wno-error=parentheses-equality"
fi

# add build modes
if is_mode "debug"; then
    set_symbols "debug"
    set_optimizes "none"
else
    set_strip "all"
    set_symbols "hidden"
    set_optimizes "smallest"
fi

# the runtime option, lua or luajit
option "runtime" "Use luajit or lua runtime" "lua"

# the readline option
option "readline"
    add_links "readline"
    add_cincludes "readline/readline.h"
    add_cfuncs "readline"

# the curses option
option "curses"
    add_links "curses"
    add_cincludes "curses.h"
option_end

# the lua-cjson option
option "lua_cjson"
    add_links "lua5.1-cjson"
    add_csnippets "
int luaopen_cjson(void *l);\n
void test() {\n
    luaopen_cjson(0);\n
}
"
option_end
add_lua_cjson() {
    if has_config "lua_cjson"; then
        add_links "lua5.1-cjson" "{public}"
    else
        add_deps "lua_cjson"
    fi
}

# add projects
if ! has_config "lua_cjson"; then
    includes "src/lua-cjson"
fi
includes "src/sv"
includes "src/lz4"
includes "src/tbox"
includes "src/xmake"
includes "src/demo"
if is_config "runtime" "luajit"; then
    includes "src/luajit"
else
    includes "src/lua"
fi


