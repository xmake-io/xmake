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
        for _, s in ipairs(subsystems) do
            if string.upper(subsystem):startswith(s) then
                valid = true
                break
            end
        end
        assert(valid, "Invalid subsystem " .. subsystem)

        local linker = target:tool("ld")
        linker = path.filename(linker)
        if linker:startswith("clang") then
            target:add("ldflags", "-Wl,-subsystem:" .. subsystem, { force = true })
        elseif linker:startswith("link") or linker:startswith("lld-link") then
            target:add("ldflags", "/SUBSYSTEM:" .. string.upper(subsystem), { force = true })
        elseif linker:startswith("gcc") or linker:startswith("g++") then
            target:add("ldflags", "-Wl,-m" .. subsystem, { force = true })
        elseif linker:startswith("ld") then
            target:add("ldflags", "-m" .. subsystem, { force = true })
        end
    end)
