#!/bin/sh

target "lua_cjson"
    set_kind "static"
    set_warnings "all"
    if is_config "runtime" "luajit"; then
        add_deps "luajit"
    else
        add_deps "lua"
    fi
    add_files "lua-cjson/dtoa.c"
    add_files "lua-cjson/lua_cjson.c"
    add_files "lua-cjson/strbuf.c"
    add_files "lua-cjson/g_fmt.c"
    # Use internal strtod() / g_fmt() code for performance and disable multi-thread
    add_defines "NDEBUG" "USE_INTERNAL_FPCONV"

