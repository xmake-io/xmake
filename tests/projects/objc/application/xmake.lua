add_rules("mode.debug", "mode.release")

target("demo")
    add_rules("xcode.application")
    add_files("src/main.m")
