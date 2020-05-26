-- define toolchain
toolchain("myclang")

    -- mark as standalone toolchain
    set_kind("standalone")
        
    -- set toolsets
    set_toolsets("cc", "clang")
    set_toolsets("cxx", "clang", "clang++")
    set_toolsets("ld", "clang++", "clang")
    set_toolsets("sh", "clang++", "clang")
    set_toolsets("ar", "ar")
    set_toolsets("ex", "ar")
    set_toolsets("strip", "strip")
    set_toolsets("mm", "clang")
    set_toolsets("mxx", "clang", "clang++")
    set_toolsets("as", "clang")

    add_defines("MYCLANG")

toolchain_end()

add_rules("mode.debug", "mode.release")

target("test")
    set_kind("static")
    add_files("src/interface.cpp")
    set_toolsets("ar", "ar")

target("demo")
    set_kind("binary")
    add_deps("test")
    add_files("src/test.cpp")
    set_toolchains("myclang")


