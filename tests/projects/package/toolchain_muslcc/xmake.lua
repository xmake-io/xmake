add_rules("mode.debug", "mode.release")

-- set cross-compliation platform
set_plat("cross")
set_arch("arm")

-- add library packages
-- for testing zlib/xmake, libplist/autoconf, libogg/cmake
add_requires("zlib", "libogg",  {system = false})
if is_host("macosx", "linux", "bsd") then
    add_requires("libplist", {system = false})
end

-- add toolchains package
add_requires("muslcc")

-- set global toolchains for target and packages
set_toolchains("@muslcc")

target("test")
    set_kind("binary")
    add_files("src/*.c")
    add_packages("zlib", "libplist", "libogg")
    if has_package("libplist") then
        add_defines("HAVE_LIBPLIST")
    end
