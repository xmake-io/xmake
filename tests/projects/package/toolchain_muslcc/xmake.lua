add_rules("mode.debug", "mode.release")

-- set cross-compliation platform
set_plat("cross")
set_arch("arm")

-- add toolchains package
add_requires("muslcc")

-- add library packages
add_requires("zlib",  {system = false})

-- set global toolchains for target and packages
set_toolchains("@muslcc")

target("test")
    set_kind("binary")
    add_files("src/*.c")
    add_packages("zlib", "openssl")
