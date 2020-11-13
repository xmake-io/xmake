add_rules("mode.debug", "mode.release")

target("test")
    add_rules("xcode.framework")
    add_files("src/framework/test.m")
    add_files("src/framework/Info.plist")
    add_headerfiles("src/framework/test.h")

target("${TARGETNAME}")
    add_rules("xcode.application")
    add_deps("test")
    add_files("src/app/*.m", "src/app/**.storyboard", "src/app/*.xcassets")
    add_files("src/app/Info.plist")
