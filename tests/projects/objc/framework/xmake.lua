add_rules("mode.debug", "mode.release")

target("test")
    add_rules("xcode.framework")
    add_files("src/test.m")
    add_files("src/Info.plist")
    add_headerfiles("src/*.h")

target("demo")
    set_kind("binary")
    add_deps("test")
    add_files("src/main.m")
