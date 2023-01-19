#!/bin/sh

# disable jit compiler for redhat and centos
jit=true
jit_plat="${plat}"
jit_arch="${arch}"
if is_plat "mingw"; then
    jit_plat="windows"
    if is_arch "x86_64"; then
        jit_arch="x64"
    else
        jit_arch="x86"
    fi
fi
if is_arch "arm64" "arm64-v8a"; then
    jit_arch="arm64"
elif is_arch "arm" "armv7"; then
    jit_arch="arm"
elif is_arch "mips64"; then
    jit_arch="mips64"
    jit=false
fi
if test -f "/etc/redhat-release"; then
    jit=false
fi
if $jit; then
    jit_dir="jit"
else
    jit_dir="nojit"
fi
jit_autogendir="luajit/autogen/${jit_plat}/${jit_dir}/${jit_arch}"

target "luajit"
    set_kind "static"
    set_default false
    set_warnings "all"

    # add include directories
    add_includedirs "${jit_autogendir}"
    add_includedirs "luajit/src" "{public}"

    # add the common source files
    add_files "luajit/src/lj_*.c"
    add_files "luajit/src/lib_*.c"
    if is_plat "mingw"; then
        add_files "${jit_autogendir}/lj_vm.o"
    else
        add_files "${jit_autogendir}/*.S"
    fi

    add_defines "USE_LUAJIT" "{public}"

    # disable jit compiler?
    if ! $jit; then
        add_defines "LUAJIT_DISABLE_JIT"
    fi

    # using internal memory management under armv7 gc will cause a crash when free strings in lua_close
    if test_eq "${jit_arch}" "arm"; then
        add_defines "LUAJIT_USE_SYSMALLOC"
    fi

    # fix call math.sin/log crash for fedora/i386/lj_vm.S with `LDFLAGS = -specs=/usr/lib/rpm/redhat/redhat-hardened-ld` in xmake.spec/%set_build_flags
    if is_plat "linux" && is_arch "i386"; then
        add_asflags "-fPIE"
        add_ldflags "-fPIE"
    fi

