
-- add modes: debug and release 
add_rules("mode.debug", "mode.release")

-- add include directories
add_includedirs(".")

-- add target
target("serial")

    -- add rules
    add_rules("wdk.kmdf.driver")

    -- add flags for rule: wdk.tracewpp
    add_values("wdk.tracewpp.flags", "-func:SerialDbgPrintEx(LEVEL,FLAGS,MSG,...)")

    -- add header file name for rule: wdk.mc
    add_values("wdk.mc.header", "serlog.h")

    -- add files
    add_files("*.c", {rule = "wdk.tracewpp"}) 
    add_files("*.mc", "*.rc", "*.inx")

