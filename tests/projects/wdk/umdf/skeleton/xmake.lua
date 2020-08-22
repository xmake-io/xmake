add_rules("mode.debug", "mode.release")

add_defines("_UNICODE", "UNICODE")

target("UMDFSkeleton")
    add_rules("wdk.env.umdf", "wdk.driver")
    add_values("wdk.tracewpp.flags", "-scan:internal.h")
    add_files("*.cpp", {rule = "wdk.tracewpp"})
    add_files("*.rc", "*.inx")
    set_values("wdk.umdf.sdkver", "1.9")
    add_shflags("/DEF:exports.def", {force = true})
    add_shflags("/ENTRY:_DllMainCRTStartup" .. (is_arch("x86") and "@12" or ""), {force = true})

