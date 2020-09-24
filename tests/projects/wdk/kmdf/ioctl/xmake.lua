add_rules("mode.debug", "mode.release")

add_includedirs(".")

target("nonpnp")
    add_rules("wdk.env.kmdf", "wdk.driver")
    add_values("wdk.tracewpp.flags", "-func:TraceEvents(LEVEL,FLAGS,MSG,...)", "-func:Hexdump((LEVEL,FLAGS,MSG,...))")
    add_files("driver/*.c", {rule = "wdk.tracewpp"})
    add_files("driver/*.rc")

target("app")
    add_rules("wdk.env.kmdf", "wdk.binary")
    add_files("exe/*.c")
    add_files("exe/*.inf")

