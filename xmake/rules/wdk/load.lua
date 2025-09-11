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
-- Copyright (C) 2015-present, Xmake Open Source Community.
--
-- @author      ruki
-- @file        load.lua
--

-- imports
import("core.project.config")
import("core.base.semver")
import("os.winver", {alias = "os_winver"})

function _add_linkflags(target, t, ...)
    local args = table.pack(...)
    if target:has_tool("ld", "clang", "clangxx") then
        for i, flag in ipairs(args) do
            if type(flag) == "string" then
                args[i] = "-Wl," .. flag
            end
        end
    end
    target:add(t, table.unpack(args))
end

function _add_ldflags(target, ...)
    _add_linkflags(target, "ldflags", ...)
end

function _add_shflags(target, ...)
    _add_linkflags(target, "shflags", ...)
end

-- load for umdf driver
function driver_umdf(target)

    -- set kind
    target:set("kind", "shared")

    -- add links
    target:add("links", "ntdll", "OneCoreUAP", "mincore", "ucrt")

    _add_shflags(target, "-NODEFAULTLIB:kernel32.lib", "-NODEFAULTLIB:user32.lib", "-NODEFAULTLIB:libucrt.lib", {force = true})

    -- add subsystem
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

    -- get wdk
    local wdk = target:data("wdk")
    if not entry and semver.compare(wdk.umdfver, "2.0") >= 0 then
        target:add("links", "WdfDriverStubUm")
    end
end

function _kernel_driver_base(target, default_entrypoint)

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

    -- compile as kernel driver
    if not target:has_tool("cc", "clang", "clangxx") then
       target:add("cxflags", "-kernel", {force = true})
    else
       -- emulate kernel mode https://learn.microsoft.com/en-us/cpp/build/reference/kernel-create-kernel-mode-binary?view=msvc-170
       target:add("cxxflags", "-fno-exceptions", "-fno-rtti")
       target:add("defines", "_KERNEL_MODE=1")
    end

    _add_ldflags(target, "-kernel", "-driver", "-nodefaultlib", {force = true})

    -- add subsystem
    if not target:values("windows.subsystem") then
        target:values_set("windows.subsystem", "native," .. os_winver.subsystem(winver))
    end

    -- set default driver entry if does not exist
    local has_entry = false
    for _, ldflag in ipairs(target:get("ldflags")) do
        if type(ldflag) == "string" then
            ldflag = ldflag:lower()
            if ldflag:find("[/%-]entry:") then
                has_entry = true
                break
            end
        end
    end
    if not has_entry then
        local arch = (target:is_arch("x86") and "@8" or "")        target:add("links", "WdfDriverEntry")
        _add_ldflags(target, "-entry:" .. default_entrypoint .. arch, {force = true})
    end
end

-- load for kmdf driver
function driver_kmdf(target)

    target:add("links", "ntoskrnl", "hal", "wmilib", "WdfLdr", "ntstrsafe", "wdmsec")

    _kernel_driver_base(target, "FxDriverEntry")
end

-- load for wdm driver
function driver_wdm(target)
    target:add("links", "ntoskrnl", "hal", "wmilib", "ntstrsafe")

    _kernel_driver_base(target, "GsDriverEntry")
end

