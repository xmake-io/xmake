
-- add modes: debug and release 
add_rules("mode.debug", "mode.release")

-- add target
target("msdsm")

    -- add rules
    add_rules("wdk.kmdf.driver")

    -- add flags for rule: wdk.tracewpp
    add_values("wdk.tracewpp.flags", "-func:TracePrint((LEVEL,FLAGS,MSG,...))")

    -- add files
    add_files("*.c", {rule = "wdk.tracewpp"}) 
    add_files("*.mof", "*.rc", "*.inf")

