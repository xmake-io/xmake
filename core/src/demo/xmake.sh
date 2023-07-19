#!/bin/sh

target "demo"
    add_deps "xmake"
    set_kind "binary"
    set_basename "xmake"
    set_targetdir "${buildir}"

    # add definitions
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

    # fix os.exec() call incorrect program from /mingw64/bin. e.g. python, ..
    #
    # because xmake is installed to /mingw64/bin/xmake,
    # os.exec/CreateProcess always gives the highest priority to finding the process from /mingw64/bin (if it exists),
    # rather than from the $PATH environment variable.
    #
    # we install the xmake executable into a separate directory to ensure
    # that os.exec() does not look for additional executables.
    #
    # @see https://github.com/xmake-io/xmake/issues/3628
    if is_host "msys"; then
        add_installfiles "${projectdir}/scripts/msys/xmake.sh" "bin" "xmake"
        add_installfiles "${buildir}/xmake.exe" "share/xmake"
    fi

    # add syslinks
    add_options "atomic"
    if is_plat "mingw" "msys" "cygwin"; then
        add_syslinks "ws2_32" "pthread" "m"
    elif is_plat "bsd"; then
        add_syslinks "pthread" "m"
    elif is_plat "haiku"; then
        add_syslinks "pthread" "network" "m"
    elif test_nz "${TERMUX_ARCH}"; then
        add_syslinks "m" "dl"
    else
        add_syslinks "pthread" "dl" "m" "c"
    fi
