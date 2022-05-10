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
        import("lib.detect.find_tool")
        local oh = assert(find_tool("oh51"), "oh51 not found")
        os.iorunv(oh.program, {target:targetfile()})
        cprint("${color.warning} hex file generated %s", target:targetfile() .. ".hex")
    end)