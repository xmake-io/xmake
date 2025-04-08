#!/bin/sh

set_project "xmake"
set_version "2.9.9" "%Y%m%d"

# set warning all
set_warnings "all"

# set language: c99
set_languages "c99"

# add definitions
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
    if ! is_kind "shared"; then
        set_symbols "hidden"
    fi
    set_optimizes "smallest"
fi

# the runtime option, lua or luajit
option "runtime" "Use luajit or lua runtime" "lua"

# always use external dependencies
option "external" "Always use external dependencies" false

# the readline option
option "readline"
    add_links "readline"
    add_cincludes "stdio.h" "readline/readline.h"
    add_cfuncs "readline"
    add_defines "XM_CONFIG_API_HAVE_READLINE"
option_end

# the curses option
option "curses"
    add_cfuncs "initscr"
    add_cincludes "curses.h"
    add_defines "XM_CONFIG_API_HAVE_CURSES"
    before_check "option_find_curses"
option_end

option_find_curses() {
    local ncurses="ncurses"
    if is_plat "mingw"; then
        ncurses="ncursesw"
    fi
    local ncurses_ldflags=""
    ncurses_ldflags=$(pkg-config --libs ${ncurses} 2>/dev/null)
    option "curses"
        if test_nz "${ncurses_ldflags}"; then
            add_cflags `pkg-config --cflags ${ncurses} 2>/dev/null`
            add_ldflags "${ncurses_ldflags}"
        else
            add_links "curses"
        fi
    option_end
}

# the atomic option
# @note some systems need link atomic, e.g. raspberrypi
option "atomic"
    add_links "atomic"
    add_csnippets "
void test() {\n
    int v;\n
    __atomic_load(&v,&v,0);\n
}"
option_end

# the lua option
option "lua"
    add_cfuncs "lua_pushstring"
    add_cincludes "lua.h" "lualib.h" "lauxlib.h"
    add_defines "LUA_COMPAT_5_1" "LUA_COMPAT_5_2" "LUA_COMPAT_5_3"
    before_check "option_find_lua"
option_end

option_find_lua() {
    local ldflags=""
    local cflags=""
    option "lua"
        # detect lua5.4 on debian
        cflags=`pkg-config --cflags lua5.4 2>/dev/null`
        ldflags=`pkg-config --libs lua5.4 2>/dev/null`
        # detect it on fedora
        if test_z "${cflags}"; then
            cflags=`pkg-config --cflags lua 2>/dev/null`
        fi
        if test_z "${ldflags}"; then
            ldflags=`pkg-config --libs lua 2>/dev/null`
        fi
        if test_z "${cflags}"; then
            cflags="-I/usr/include/lua5.4"
        fi
        if test_z "${ldflags}"; then
            ldflags="-llua5.4"
        fi
        add_cflags "${cflags}"
        add_ldflags "${ldflags}"
    option_end
}

# the luajit option
option "luajit"
    add_cfuncs "lua_pushstring"
    add_cincludes "lua.h" "lualib.h" "lauxlib.h"
    add_defines "USE_LUAJIT"
    before_check "option_find_luajit"
option_end

option_find_luajit() {
    local ldflags=""
    local cflags=""
    option "luajit"
        cflags=`pkg-config --cflags luajit 2>/dev/null`
        ldflags=`pkg-config --libs luajit 2>/dev/null`
        if test_z "${cflags}"; then
            cflags="-I/usr/include/luajit-2.1"
        fi
        if test_z "${ldflags}"; then
            ldflags="-lluajit"
        fi
        add_cflags "${cflags}"
        add_ldflags "${ldflags}"
    option_end
}

# the lz4 option
option "lz4"
    add_cfuncs "LZ4F_compressFrame"
    add_cincludes "lz4.h" "lz4frame.h"
    before_check "option_find_lz4"
option_end

option_find_lz4() {
    local ldflags=""
    local cflags=""
    option "lz4"
        cflags=`pkg-config --cflags liblz4 2>/dev/null`
        ldflags=`pkg-config --libs liblz4 2>/dev/null`
        if test_z "${cflags}"; then
            cflags="-I/usr/include"
        fi
        if test_z "${ldflags}"; then
            ldflags="-llz4"
        fi
        add_cflags "${cflags}"
        add_ldflags "${ldflags}"
    option_end
}

# the sv option
option "sv"
    add_cfuncs "semver_tryn"
    add_cincludes "semver.h"
    add_links "sv"
    before_check "option_find_sv"
option_end

option_find_sv() {
    local ldflags=""
    local cflags=""
    option "sv"
        cflags=`pkg-config --cflags libsv 2>/dev/null`
        ldflags=`pkg-config --libs libsv 2>/dev/null`
        if test_z "${cflags}"; then
            cflags="-I/usr/include"
        fi
        if test_z "${ldflags}"; then
            ldflags="-lsv"
        fi
        add_cflags "${cflags}"
        add_ldflags "${ldflags}"
    option_end
}

# the tbox option
option "tbox"
    add_cfuncs "tb_exit" "tb_md5_init" "tb_charset_conv_data"
    add_cincludes "tbox/tbox.h"
    add_links "tbox"
    before_check "option_find_tbox"
option_end

option_find_tbox() {
    local ldflags=""
    local cflags=""
    option "tbox"
        cflags=`pkg-config --cflags libtbox 2>/dev/null`
        ldflags=`pkg-config --libs libtbox 2>/dev/null`
        if test_z "${cflags}"; then
            cflags="-I/usr/include"
        fi
        if test_z "${ldflags}"; then
            ldflags="-ltbox"
        fi
        add_cflags "${cflags}"
        add_ldflags "${ldflags}"
        # ubuntu armv7/armel maybe need it
        if is_plat "linux" && is_arch "armv7" "arm"; then
            add_ldflags "-latomic"
        fi
    option_end
}

# add projects
if ! has_config "external"; then
    if is_config "runtime" "luajit"; then
        includes "src/luajit"
    else
        includes "src/lua"
    fi
    includes "src/lua-cjson"
    includes "src/lz4"
    includes "src/sv"
    includes "src/tbox"
fi
includes "src/xmake"
includes "src/cli"
