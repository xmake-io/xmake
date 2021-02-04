add_rules("mode.debug", "mode.release")

-- set muslcc as global toolchain
add_requires("muslcc")
set_toolchains("muslcc")

-- explicitly specify the package toolchain
add_requires("zlib", {configs = {toolchains = "muslcc"}})

-- use global toolchain: muslcc
add_requires("pcre2")

target("test")
    set_kind("binary")
    add_files("src/*.c")
    add_packages("zlib", "pcre2")
