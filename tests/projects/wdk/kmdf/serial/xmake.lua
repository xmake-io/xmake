add_rules("mode.debug", "mode.release")

target("wdfserial")
    add_rules("wdk.env.kmdf", "wdk.driver")
    add_values("wdk.tracewpp.flags", "-func:SerialDbgPrintEx(LEVEL,FLAGS,MSG,...)")
    add_values("wdk.mc.header", "serlog.h")
    add_files("*.c", {rule = "wdk.tracewpp"})
    add_files("*.mc", "*.rc", "*.inx")

