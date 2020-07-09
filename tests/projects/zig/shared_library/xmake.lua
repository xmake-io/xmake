add_rules("mode.debug", "mode.release")

target("testlib")
    set_kind("shared")
    add_files("src/test.zig")

target("test")
    set_kind("binary")
    add_deps("testlib")
    add_files("src/main.zig")

