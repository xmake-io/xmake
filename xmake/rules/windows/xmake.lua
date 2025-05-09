rule("win.subsystem.console")
    add_deps("win.subsystem")
    on_load(function(target)
        target:data_set("win.subsystem", "console")
    end)

rule("win.subsystem.windows")
    add_deps("win.subsystem")
    on_load(function(target)
        target:data_set("win.subsystem", "windows")
    end)

rule("win.subsystem")
    on_config("mingw", "windows", function(target)
        local subsystems = {
            "BOOT_APPLICATION", "CONSOLE", "EFI_APPLICATION", "EFI_BOOT_SERVICE_DRIVER", "EFI_ROM", "EFI_RUNTIME_DRIVER", "NATIVE", "POSIX", "WINDOWS"
        }

        local subsystem = target:data("win.subsystem")
        local valid = false
        local startswith = string.startswith
        local upper = string.upper
        for _, s in ipairs(subsystems) do
            if startswith(upper(subsystem), s) then
                valid = true
                break
            end
        end
        assert(valid, "Invalid subsystem " .. subsystem)

        local linker = target:tool("ld")
        linker = path.filename(linker)
        if startswith(linker, "clang") then
            target:add("ldflags", "-Wl,-subsystem:" .. subsystem, { force = true })
        elseif startswith(linker, "link") or startswith(linker, "lld-link") then
            target:add("ldflags", "/SUBSYSTEM:" .. upper(subsystem), { force = true })
        elseif startswith(linker, "gcc") or startswith(linker, "g++") then
            target:add("ldflags", "-Wl,-m" .. subsystem, { force = true })
        elseif startswith(linker, "ld") then
            target:add("ldflags", "-m" .. subsystem, { force = true })
        end
    end)
