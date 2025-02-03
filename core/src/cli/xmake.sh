#!/bin/sh

target "cli"
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
    add_installfiles "${projectdir}/(xmake/scripts/*)" "share"
    add_installfiles "${projectdir}/(xmake/scripts/cmake_importfiles/**)" "share"
    add_installfiles "${projectdir}/(xmake/scripts/completions/**)" "share"
    add_installfiles "${projectdir}/(xmake/scripts/xpack/**)" "share"
    add_installfiles "${projectdir}/(xmake/scripts/xrepo/**)" "share"
    add_installfiles "${projectdir}/(xmake/scripts/virtualenvs/**)" "share"
    add_installfiles "${projectdir}/(xmake/scripts/conan/**)" "share"
    add_installfiles "${projectdir}/(xmake/scripts/module/**)" "share"
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
        after_install "xmake_after_install"
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

xmake_after_install() {
    local target=${1}
    local installdir=${2}
    if test_eq "${project_generator}" "gmake"; then
        print "\t@if test -f ${installdir}/bin/xmake.exe; then rm ${installdir}/bin/xmake.exe; fi" >> "${xmake_sh_makefile}"
        print "\t@cp ${projectdir}/scripts/msys/xmake.sh ${installdir}/bin/xmake" >> "${xmake_sh_makefile}"
        print "\t@cp ${projectdir}/scripts/msys/xmake.cmd ${installdir}/bin/xmake.cmd" >> "${xmake_sh_makefile}"
        print "\t@cp ${projectdir}/scripts/msys/xmake.ps1 ${installdir}/bin/xmake.ps1" >> "${xmake_sh_makefile}"
        print "\t@cp ${buildir}/xmake.exe ${installdir}/share/xmake" >> "${xmake_sh_makefile}"
    fi
}
