rule("platform.windows.subsystem")
    on_config("mingw", "windows", function(target)
        local subsystems = {
            "BOOT_APPLICATION", "CONSOLE", "EFI_APPLICATION", "EFI_BOOT_SERVICE_DRIVER", "EFI_ROM", "EFI_RUNTIME_DRIVER", "NATIVE", "POSIX", "WINDOWS"
        }

        local subsystem = target:values("windows.subsystem")
        if subsystem then
            local valid = false
            local upper = string.upper
            for _, s in ipairs(subsystems) do
                if (subsystem:upper():startwiths(s)) then
                    valid = true
                    break
                end
            end
            assert(valid, "Invalid subsystem " .. subsystem)

            if target:has_tool("ld", "clang") then
                target:add("ldflags", "-Wl,-subsystem:" .. subsystem, { force = true })
            elseif target:has_tool("ld", "link", "lld-link") then
                target:add("ldflags", "/SUBSYSTEM:" .. upper(subsystem), { force = true })
            elseif target:has_tool("ld", "gcc", "g++") then
                target:add("ldflags", "-Wl,-m" .. subsystem, { force = true })
            elseif target:has_tool("ld", "ld") then
                target:add("ldflags", "-m" .. subsystem, { force = true })
            end
        end
    end)
