add_rules("mode.debug", "mode.release")

target("sampledsm")
    add_rules("wdk.env.wdm", "wdk.driver")
    add_values("wdk.tracewpp.flags", "-func:TracePrint((LEVEL,FLAGS,MSG,...))")
    add_files("*.c", {rule = "wdk.tracewpp"})
    add_files("*.rc", "*.inf")
    add_files("*.mof|msdsm.mof")

    -- add file msdsm.mof and modify default wdk.mof.header for this file
    add_files("msdsm.mof", {values = {wdk_mof_header = "msdsmwmi.h"}})

    set_pcheader("precomp.h")
    add_links("mpio")

