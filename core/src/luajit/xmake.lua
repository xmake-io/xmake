-- disable jit compiler for redhat and centos
local jit = true
local plat = "$(plat)"
local arch = "$(arch)"
if is_plat("msys", "cygwin") then
    plat = "windows"
    arch = is_arch("x86_64") and "x64" or "x86"
end
if is_arch("arm64", "arm64-v8a") then
    arch = "arm64"
elseif is_arch("arm.*") then
    arch = "arm"
elseif is_arch("mips64.*") then
    arch = "mips64"
    jit = false
end
if os.isfile("/etc/redhat-release") then
    jit = false
end
local autogendir = path.join("autogen", plat, jit and "jit" or "nojit", arch)

-- add target
target("luajit")

    -- make as a static library
    set_kind("static")

    -- set warning all and disable error
    set_warnings("all")

    -- disable c99(/TP) for windows
    if is_plat("windows") then
        set_languages("c89")
    end

    -- add header files
    add_headerfiles("luajit/src/(*.h)", {prefixdir = "luajit"})

    -- add include directories
    add_includedirs(autogendir)
    add_includedirs("luajit/src", {public = true})

    -- add the common source files
    add_files("luajit/src/*.c|ljamalg.c|luajit.c")
    if is_plat("windows") then
        add_files(autogendir .. "/lj_vm.obj")
    elseif is_plat("msys", "cygwin") then
        add_files(autogendir .. "/lj_vm.o")
    else
        add_files(autogendir .. "/*.S")
    end

    -- disable jit compiler?
    if not jit then
        add_defines("LUAJIT_DISABLE_JIT")
    end

    -- using internal memory management under armv7, gc will cause a crash when free strings in lua_close()
    if arch == "arm" then
        add_defines("LUAJIT_USE_SYSMALLOC")
    end

    -- fix call math.sin/log crash for fedora/i386/lj_vm.S with `LDFLAGS = -specs=/usr/lib/rpm/redhat/redhat-hardened-ld` in xmake.spec/%set_build_flags
    if is_plat("linux") and is_arch("i386") then
        add_asflags("-fPIE")
        add_ldflags("-fPIE")
    end

    -- enable lua5.2 compat, @see http://luajit.org/extensions.html
    --[[
    add_defines("LUAJIT_ENABLE_LUA52COMPAT")
    if not is_plat("windows") then
        add_cflags("-Wno-error=unused-function")
    end]]

       
