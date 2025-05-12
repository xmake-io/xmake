--!A cross-platform build utility based on Lua
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--
-- Copyright (C) 2015-present, TBOOX Open Source Group.
--
-- @author      ruki, Arthapz
-- @file        xmake.lua
--

-- define rule: subsystem
-- set any of  "boot_application" "console" "efi_application" "efi_boot_service_driver" "efi_rom" "efi_runtime_driver" "native" "posix" "windows"
-- with target:set_values("windows.subsystem", <your value>) and the rule will pass the proper flag to the linker
rule("platform.windows.subsystem")
    on_config("mingw", "windows", function(target)
        local subsystems = {
            "BOOT_APPLICATION", "CONSOLE", "EFI_APPLICATION", "EFI_BOOT_SERVICE_DRIVER", "EFI_ROM", "EFI_RUNTIME_DRIVER", "NATIVE", "POSIX", "WINDOWS"
        }

        local subsystem = target:values("windows.subsystem")
        if subsystem then
            local valid = false
            for _, s in ipairs(subsystems) do
                if subsystem:upper():startswith(s) then
                    valid = true
                    break
                end
            end
            assert(valid, "Invalid subsystem " .. subsystem)

            if target:has_tool("ld", "clang", "clangxx", "clang_cl") then
                target:add("ldflags", "-Wl,-subsystem:" .. subsystem, { force = true })
            elseif target:has_tool("ld", "link", "lld-link") then
                target:add("ldflags", "/SUBSYSTEM:" .. upper(subsystem), { force = true })
            elseif target:has_tool("ld", "gcc", "gxx") then
                target:add("ldflags", "-Wl,-m" .. subsystem, { force = true })
            elseif target:has_tool("ld", "lld") then
                target:add("ldflags", "-subsystem:" .. subsystem, { force = true })
            elseif target:has_tool("ld", "ld") then
                target:add("ldflags", "-m" .. subsystem, { force = true })
            end
        end
    end)
