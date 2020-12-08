add_rules("mode.debug", "mode.release")

target("demo")
    set_kind("binary")
    add_files("src/*.c")
    add_files("src/*.zig")

