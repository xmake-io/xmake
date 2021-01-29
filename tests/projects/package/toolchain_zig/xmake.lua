add_rules("mode.debug", "mode.release")
add_requires("zig 0.7.x")

target("test")
    set_kind("binary")
    add_files("src/*.c")
    set_toolchains("zig", {packages = "zig"})
