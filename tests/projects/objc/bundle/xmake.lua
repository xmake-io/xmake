add_rules("mode.debug", "mode.release")

target("test")
    add_rules("xcode.bundle")
    add_files("src/test.m")
    add_files("src/Info.plist")

