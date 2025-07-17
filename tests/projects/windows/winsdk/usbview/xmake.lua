add_rules("mode.debug", "mode.release")

target("usbview")
    add_rules("win.sdk.application")
    add_files("*.c", "*.rc")
    add_files("xmlhelper.cpp", {rules = "win.sdk.dotnet"})
    set_exceptions("none")

