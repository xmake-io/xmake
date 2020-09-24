-- define toolchain
toolchain("myclang")

    -- mark as standalone toolchain
    set_kind("standalone")

    -- set toolset
    set_toolset("cc", "clang")
    set_toolset("cxx", "clang", "clang++")
    set_toolset("ld", "clang++", "clang")
    set_toolset("sh", "clang++", "clang")
    set_toolset("ar", "ar")
    set_toolset("ex", "ar")
    set_toolset("strip", "strip")
    set_toolset("mm", "clang")
    set_toolset("mxx", "clang", "clang++")
    set_toolset("as", "clang")

    add_defines("MYCLANG")

toolchain_end()

add_rules("mode.debug", "mode.release")

target("test")
    set_kind("static")
    add_files("src/interface.cpp")
    set_toolset("ar", "ar")

target("demo")
    set_kind("binary")
    add_deps("test")
    add_files("src/test.cpp")
    set_toolchains("myclang")


