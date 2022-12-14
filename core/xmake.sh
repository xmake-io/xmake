#!/bin/sh

set_project "xmake"
set_version "2.7.3" "%Y%m%d%H%M"

# set warning all as error
set_warnings "all" "error"

# set language: c99
set_languages "c99"

# add defines
add_defines "_GNU_SOURCE=1"  "_FILE_OFFSET_BITS=64"  "_LARGEFILE_SOURCE"

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
    set_description "Enable or disable readline library"
    add_links "readline"
    add_cincludes "readline/readline.h"
    add_cfuncs "readline"
#    add_defines("XM_CONFIG_API_HAVE_READLINE")

# the curses option
option "curses"
    set_description "Enable or disable curses library"
    add_links "curses"
    add_cincludes "curses.h"
#    add_defines "XM_CONFIG_API_HAVE_CURSES"
option_end

# add projects
includes "src/lua"
includes "src/lua-cjson"
includes "src/sv"
includes "src/lz4"
includes "src/tbox"
#includes "src/xmake"
#includes "src/demo"
#if is_config "runtime" "luajit" then
#    includes "src/luajit"
#fi


