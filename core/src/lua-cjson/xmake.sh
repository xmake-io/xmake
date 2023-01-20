#!/bin/sh

target "lua_cjson"
    set_kind "static"
    set_default false
    set_warnings "all"
    if has_config "external"; then
        if is_config "runtime" "luajit"; then
            if has_config "luajit"; then
                add_options "luajit" "{public}"
            fi
        else
            if has_config "lua"; then
                add_options "lua" "{public}"
            fi
        fi
    else
        if is_config "runtime" "luajit"; then
            add_deps "luajit"
        else
            add_deps "lua"
        fi
    fi
    add_files "lua-cjson/dtoa.c"
    add_files "lua-cjson/lua_cjson.c"
    add_files "lua-cjson/strbuf.c"
    add_files "lua-cjson/g_fmt.c"
    # Use internal strtod() / g_fmt() code for performance and disable multi-thread
    add_defines "NDEBUG" "USE_INTERNAL_FPCONV"
    add_defines "XM_CONFIG_API_HAVE_LUA_CJSON" "{public}"

