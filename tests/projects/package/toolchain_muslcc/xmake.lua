add_rules("mode.debug", "mode.release")

-- set cross-compliation platform
set_plat("cross")
set_arch("arm")

-- lock requires
set_policy("package.requires_lock", true)

-- custom toolchain
toolchain("my_muslcc")
    set_homepage("https://musl.cc/")
    set_description("The musl-based cross-compilation toolchains")
    set_kind("cross")
    on_load(function (toolchain)
        toolchain:load_cross_toolchain()
        if toolchain:is_arch("arm") then
            toolchain:add("cxflags", "-march=armv7-a", "-msoft-float", {force = true})
            toolchain:add("ldflags", "-march=armv7-a", "-msoft-float", {force = true})
        end
        toolchain:add("syslinks", "gcc", "c")
    end)
toolchain_end()

-- add library packages
-- for testing zlib/xmake, libplist/autoconf, libogg/cmake
add_requires("zlib", "libogg",  {system = false})
if is_host("macosx", "linux", "bsd", "solaris") then
    add_requires("libplist", {system = false})
end

-- add toolchains package
add_requires("muslcc")

-- set global toolchains for target and packages
set_toolchains("my_muslcc@muslcc")

-- use the builltin toolchain("muslcc") instead of "my_muslcc"
--set_toolchains("@muslcc")

target("test")
    set_kind("binary")
    add_files("src/*.c")
    add_packages("zlib", "libplist", "libogg")
    if has_package("libplist") then
        add_defines("HAVE_LIBPLIST")
    end
