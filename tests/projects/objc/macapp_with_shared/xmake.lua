add_rules("mode.debug", "mode.release")

target("test")
    set_kind("shared")
    add_files("src/test.c")

target("demo")
    add_rules("xcode.application")
    add_deps("test")
    add_files("src/*.m", "src/**.storyboard", "src/*.xcassets")
    add_files("src/Info.plist")
