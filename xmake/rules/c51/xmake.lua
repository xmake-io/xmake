rule("c51.static")
    on_load(function (target)


        -- we disable checking flags for cross toolchain automatically
        target:set("policy", "check.auto_ignore_flags", false)
        target:set("policy", "check.auto_map_flags", false)

        -- set default output binary
        target:set("kind", "binary")
        if not target:get("extension") then
            target:set("extension", "")
        end
    end)

    after_link(function(target)
        import("detect.tools.find_oh51")
        oh = find_oh51()
        os.iorunv(oh, {target:targetfile()})
        cprint("${color.warning} hex file generated %s", target:targetfile() .. ".hex")
    end)