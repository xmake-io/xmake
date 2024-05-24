#!/bin/sh

target "lua"
    set_kind "static"
    set_default false
    set_warnings "all"

    # add include directories
    add_includedirs "lua" "{public}"

    # add the common source files
    add_files "lua/lapi.c"
    add_files "lua/lauxlib.c"
    add_files "lua/lbaselib.c"
    add_files "lua/lcode.c"
    add_files "lua/lcorolib.c"
    add_files "lua/lctype.c"
    add_files "lua/ldblib.c"
    add_files "lua/ldebug.c"
    add_files "lua/ldo.c"
    add_files "lua/ldump.c"
    add_files "lua/lfunc.c"
    add_files "lua/lgc.c"
    add_files "lua/linit.c"
    add_files "lua/liolib.c"
    add_files "lua/llex.c"
    add_files "lua/lmathlib.c"
    add_files "lua/lmem.c"
    add_files "lua/loadlib.c"
    add_files "lua/lobject.c"
    add_files "lua/lopcodes.c"
    add_files "lua/loslib.c"
    add_files "lua/lparser.c"
    add_files "lua/lstate.c"
    add_files "lua/lstring.c"
    add_files "lua/lstrlib.c"
    add_files "lua/ltable.c"
    add_files "lua/ltablib.c"
    add_files "lua/ltm.c"
    add_files "lua/lundump.c"
    add_files "lua/lutf8lib.c"
    add_files "lua/lvm.c"
    add_files "lua/lzio.c"

    # add definitions
    add_defines "LUA_COMPAT_5_1" "LUA_COMPAT_5_2" "LUA_COMPAT_5_3" "{public}"
    if is_plat "mingw"; then true
        # it has been defined in luaconf.h
        #add_defines "LUA_USE_WINDOWS"
    elif is_plat "macosx"; then
        add_defines "LUA_USE_MACOSX"
    else
        add_defines "LUA_USE_LINUX"
    fi

