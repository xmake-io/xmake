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
-- @author      ruki
-- @file        load.lua
--

-- imports
import("core.project.config")
import("os.winver", {alias = "os_winver"})

-- load for umdf driver
function driver_umdf(target)

    -- set kind
    target:set("kind", "shared")

    -- add links
    target:add("links", "ntdll", "OneCoreUAP", "mincore", "ucrt")
    target:add("shflags", "-NODEFAULTLIB:kernel32.lib", "-NODEFAULTLIB:user32.lib", "-NODEFAULTLIB:libucrt.lib", {force = true})

    -- add subsystem
    local winver = target:values("wdk.env.winver") or config.get("wdk_winver")
    if not target:values("windows.subsystem") then
        target:values_set("windows.subsystem", "windows," .. os_winver.subsystem(winver))
    end

    -- set default driver entry if does not exist
    local entry = false
    for _, ldflag in ipairs(target:get("shflags")) do
        ldflag = ldflag:lower()
        if ldflag:find("[/%-]entry:") then
            entry = true
            break
        end
    end
    if not entry then
        target:add("links", "WdfDriverStubUm")
    end
end

-- load for kmdf driver
function driver_kmdf(target)

    -- set kind
    target:set("kind", "binary")

    -- set filename: xxx.sys
    target:set("filename", target:basename() .. ".sys")

    -- add links
    local winver = target:values("wdk.env.winver") or config.get("wdk_winver")
    if winver and os_winver.version(winver) >= os_winver.version("win8") then
        target:add("links", "BufferOverflowFastFailK")
    else
        target:add("links", "BufferOverflowK")
    end
    target:add("links", "ntoskrnl", "hal", "wmilib", "WdfLdr", "ntstrsafe", "wdmsec")

    -- compile as kernel driver
    target:add("cxflags", "-kernel", {force = true})
    target:add("ldflags", "-kernel", "-driver", {force = true})
    target:add("ldflags", "-nodefaultlib", {force = true})

    -- add subsystem
    if not target:values("windows.subsystem") then
        target:values_set("windows.subsystem", "native," .. os_winver.subsystem(winver))
    end

    -- set default driver entry if does not exist
    local entry = false
    for _, ldflag in ipairs(target:get("ldflags")) do
        if type(ldflag) == "string" then
            ldflag = ldflag:lower()
            if ldflag:find("[/%-]entry:") then
                entry = true
                break
            end
        end
    end
    if not entry then
        target:add("links", "WdfDriverEntry")
        target:add("ldflags", "-entry:FxDriverEntry" .. (is_arch("x86") and "@8" or ""), {force = true})
    end
end

-- load for wdm driver
function driver_wdm(target)

    -- set kind
    target:set("kind", "binary")

    -- set filename: xxx.sys
    target:set("filename", target:basename() .. ".sys")

    -- add links
    local winver = target:values("wdk.env.winver") or config.get("wdk_winver")
    if winver and os_winver.version(winver) >= os_winver.version("win8") then
        target:add("links", "BufferOverflowFastFailK")
    else
        target:add("links", "BufferOverflowK")
    end
    target:add("links", "ntoskrnl", "hal", "wmilib", "ntstrsafe")

    -- compile as kernel driver
    target:add("cxflags", "-kernel", {force = true})
    target:add("ldflags", "-kernel", "-driver", {force = true})
    target:add("ldflags", "-nodefaultlib", {force = true})

    -- add subsystem
    if not target:values("windows.subsystem") then
        target:values_set("windows.subsystem", "native," .. os_winver.subsystem(winver))
    end

    -- set default driver entry if does not exist
    local entry = false
    for _, ldflag in ipairs(target:get("ldflags")) do
        if type(ldflag) == "string" then
            ldflag = ldflag:lower()
            if ldflag:find("[/%-]entry:") then
                entry = true
                break
            end
        end
    end
    if not entry then
        target:add("ldflags", "-entry:GsDriverEntry" .. (is_arch("x86") and "@8" or ""), {force = true})
    end
end

