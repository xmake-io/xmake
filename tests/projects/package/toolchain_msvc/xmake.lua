add_rules("mode.debug", "mode.release")
add_requires("msvc")

target("test")
    set_kind("binary")
    add_files("src/*.c")
    set_toolchains("@msvc")
