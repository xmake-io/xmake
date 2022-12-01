add_rules("mode.debug", "mode.release")

target("test")
    add_rules("win.sdk.application")
    add_files("*.rc", "*.cpp")

