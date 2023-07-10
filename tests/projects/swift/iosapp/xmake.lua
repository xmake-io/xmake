add_rules("mode.debug", "mode.release")

set_plat("iphoneos")
set_arch("arm64")

target("test")
    add_rules("xcode.application")
    add_files("src/*.swift", "src/**.storyboard", "src/*.xcassets")
    add_files("src/Info.plist")
