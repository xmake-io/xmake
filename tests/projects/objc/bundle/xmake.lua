add_rules("mode.debug", "mode.release")

target("test")
    add_rules("xcode.bundle")
    add_files("src/test.m")

target("demo")
    set_kind("binary")
    add_deps("test")
    add_files("src/main.m")
