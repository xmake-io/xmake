add_rules("mode.debug", "mode.release")

-- set cross-compliation platform
set_plat("cross")
set_arch("arm")

-- add library packages
add_requires("zlib", "libplist",  {system = false})

-- add toolchains package
add_requires("muslcc")

-- set global toolchains for target and packages
set_toolchains("@muslcc")

target("test")
    set_kind("binary")
    add_files("src/*.c")
    add_packages("zlib", "libplist")
