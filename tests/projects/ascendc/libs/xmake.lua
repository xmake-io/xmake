add_rules("mode.debug", "mode.release")

target("ascendc_static")
    set_kind("static")
    add_files("src/lib.asc")
    add_ascnpuarchs("dav-2201")

target("ascendc_shared")
    set_kind("shared")
    add_files("src/lib.asc")
    add_ascnpuarchs("dav-2201")

target("ascendc_libs_bin")
    add_deps("ascendc_static", "ascendc_shared")
    set_kind("binary")
    add_files("src/main.asc")
    add_ascnpuarchs("dav-2201")
