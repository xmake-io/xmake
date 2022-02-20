add_rules("mode.debug", "mode.release")
add_requires("zig 0.9.x")

target("test")
    set_kind("binary")
    add_files("src/*.cpp")
    set_toolchains("@zig")


