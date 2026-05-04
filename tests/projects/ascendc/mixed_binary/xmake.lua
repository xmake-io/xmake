add_rules("mode.debug", "mode.release")

target("ascendc_mixed")
    set_kind("binary")
    add_files("src/main.asc", "src/helper.aicpu")
    add_ascnpuarchs("dav-2201")
