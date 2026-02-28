add_rules("mode.debug", "mode.release")

target("${TARGETNAME}")
    add_rules("xcode.application")
    add_files("src/*.m", "src/**.storyboard", "src/*.xcassets")
    add_files("src/Info.plist")
