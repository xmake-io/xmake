add_rules("mode.debug", "mode.release")

add_requires("zig >=0.10")

target("demo")
    set_kind("binary")
    add_files("src/*.c")
    add_files("src/*.zig")
    set_toolchains("@zig", {zigcc = false})

