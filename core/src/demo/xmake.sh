#!/bin/sh

target "demo"
    add_deps "xmake"
    set_kind "binary"
    set_basename "xmake"
    set_targetdir "${buildir}"

    # add defines
    add_defines "__tb_prefix__=\"xmake\""

    # add includes directory
    add_includedirs "${projectdir}/core" "${projectdir}/core/src"

    # add the common source files
    add_files "**.c"

    # add links
    if is_plat "macosx" && is_config "runtime" "luajit"; then
        add_ldflags "-all_load" "-pagezero_size 10000" "-image_base 100000000"
    elif is_plat "mingw"; then
        add_ldflags "-static-libgcc"
    fi

    # add install files
    add_installfiles "${projectdir}/(xmake/**.lua)" "share"
    add_installfiles "${projectdir}/(xmake/scripts/**)" "share"
    add_installfiles "${projectdir}/(xmake/templates/**)" "share"
    add_installfiles "${projectdir}/scripts/xrepo.sh" "bin" "xrepo"

    # add syslinks
    add_options "atomic"
    if is_plat "mingw" "msys" "cygwin"; then
        add_syslinks "ws2_32" "pthread" "m"
    elif is_plat "bsd"; then
        add_syslinks "pthread" "m"
    elif test_nz "${TERMUX_ARCH}"; then
        add_syslinks "m" "dl"
    else
        add_syslinks "pthread" "dl" "m" "c"
    fi
