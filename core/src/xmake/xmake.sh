#!/bin/sh

target "xmake"
    set_kind "static"
    set_default false

    # add deps
    add_deps "sv" "lz4" "tbox"
    local libs="lua_cjson lua"
    for lib in $libs; do
        if has_config "$lib"; then
            add_options "$lib" "{public}"
        else
            add_deps "$lib"
        fi
    done

    # add defines
    add_defines "__tb_prefix__=\"xmake\""
    if is_mode "debug"; then
        add_defines "__tb_debug__" "{public}"
    fi

    # set the auto-generated config.h
    set_configdir "${buildir}/${plat}/${arch}/${mode}"
    add_configfiles "xmake.config.h.in"

    # add includes directory
    add_includedirs ".." "{public}"
    add_includedirs "${buildir}/${plat}/${arch}/${mode}" "{public}"
    add_includedirs "../xxhash"

    # add the common source files
    add_files "*.c"
    add_files "base64/*.c"
    add_files "bloom_filter/*.c"
    add_files "curses/*.c"
    add_files "fwatcher/*.c"
    add_files "hash/*.c"
    add_files "io/*.c"
    add_files "libc/*.c"
    add_files "lz4/*.c"
    add_files "os/*.c"
    add_files "path/*.c"
    add_files "process/*.c"
    add_files "readline/*.c"
    add_files "sandbox/*.c"
    add_files "semver/*.c"
    add_files "string/*.c"
    add_files "tty/*.c"
    if is_plat "mingw"; then
        add_files "winos/*.c"
    fi

    # enable readline
    if has_config "readline"; then
        add_defines "XM_CONFIG_API_HAVE_READLINE" "{public}"
        add_links "readline" "{public}"
    fi

    # enable curses
    if has_config "curses"; then
        add_defines "XM_CONFIG_API_HAVE_CURSES" "{public}"
        add_links "curses" "{public}"
    fi
