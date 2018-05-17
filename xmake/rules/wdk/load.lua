--!A cross-platform build utility based on Lua
--
-- Licensed to the Apache Software Foundation (ASF) under one
-- or more contributor license agreements.  See the NOTICE file
-- distributed with this work for additional information
-- regarding copyright ownership.  The ASF licenses this file
-- to you under the Apache License, Version 2.0 (the
-- "License"); you may not use this file except in compliance
-- with the License.  You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- 
-- Copyright (C) 2015 - 2018, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        load.lua
--

-- imports
import("core.project.config")

-- load for umdf driver
function umdf_driver(target)

    -- get wdk
    local wdk = target:data("wdk")

    -- set kind
    target:set("kind", "shared")

    -- add defines
    local arch = config.arch()
    local umdfver = wdk.umdfver:split('%.')
    if arch == "x64" then
        target:add("defines", "_WIN64", "_AMD64_", "AMD64")
    else
        target:add("cxflags", "-Gz", {force = true})
        target:add("defines", "_X86_=1", "i386=1", "STD_CALL")
        target:add("defines", "DEPRECATE_DDK_FUNCTIONS=1", "MSC_NOOPT", "_ATL_NO_WIN_SUPPORT", "_WINDLL")
    end
    target:add("defines", "UMDF_VERSION_MAJOR=" .. umdfver[1], "UMDF_VERSION_MINOR=" .. umdfver[2], "UMDF_USING_NTSTATUS")
    target:add("defines", "WIN32_LEAN_AND_MEAN=1", "_WIN32_WINNT=0x0A00", "WINVER=0x0A00", "WINNT=1", "NTDDI_VERSION=0x0A000004", "_WINDLL")

    -- add include directories
    target:add("includedirs", path.join(wdk.includedir, wdk.sdkver, "um"))
    target:add("includedirs", path.join(wdk.includedir, "wdf", "umdf", wdk.umdfver))

    -- add link directories
    target:add("linkdirs", path.join(wdk.libdir, wdk.sdkver, "um", arch))
    target:add("linkdirs", path.join(wdk.libdir, "wdf", "umdf", arch, wdk.umdfver))

    -- add links
    target:add("links", "ntdll", "OneCoreUAP", "mincore", "ucrt")
    target:add("shflags", "-NODEFAULTLIB:kernel32.lib", "-NODEFAULTLIB:user32.lib", "-NODEFAULTLIB:libucrt.lib", {force = true})

    -- set subsystem: windows, TODO 10.00
    target:add("shflags", "-subsystem:windows,10.00", {force = true})

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

-- load for umdf binary
function umdf_binary(target)

    -- get wdk
    local wdk = target:data("wdk")

    -- set kind
    target:set("kind", "binary")

    -- add defines
    local arch = config.arch()
    if arch == "x64" then
        target:add("defines", "_WIN64", "_AMD64_", "AMD64")
    else
        target:add("defines", "_X86_=1", "i386=1", "STD_CALL")
        target:add("defines", "_ATL_NO_WIN_SUPPORT", "_CRT_USE_WINAPI_PARTITION_APP")
    end
    target:add("defines", "WIN32_LEAN_AND_MEAN=1", "_WIN32_WINNT=0x0A00", "WINVER=0x0A00", "WINNT=1", "NTDDI_VERSION=0x0A000004", "_WINDLL")

    -- add include directories
    target:add("includedirs", path.join(wdk.includedir, wdk.sdkver, "um"))
    target:add("includedirs", path.join(wdk.includedir, "wdf", "umdf", wdk.umdfver))

    -- add link directories
    target:add("linkdirs", path.join(wdk.libdir, wdk.sdkver, "um", arch))
    target:add("linkdirs", path.join(wdk.libdir, "wdf", "umdf", arch, wdk.umdfver))

    -- add links
    target:add("links", "ntdll", "OneCoreUAP", "mincore", "ucrt")
    target:add("ldflags", "-NODEFAULTLIB:kernel32.lib", "-NODEFAULTLIB:user32.lib", "-NODEFAULTLIB:libucrt.lib", {force = true})
end

-- load for kmdf driver
function kmdf_driver(target)

    -- get wdk
    local wdk = target:data("wdk")

    -- set kind
    target:set("kind", "binary")

    -- set filename: xxx.sys
    target:set("filename", target:basename() .. ".sys")

    -- add defines
    local arch = config.arch()
    local kmdfver = wdk.kmdfver:split('%.')
    if arch == "x64" then
        target:add("defines", "_WIN64", "_AMD64_", "AMD64")
    else
        target:add("cxflags", "-Gz", {force = true})
        target:add("defines", "_X86_=1", "i386=1", "STD_CALL")
    end
    target:add("defines", "WIN32_LEAN_AND_MEAN=1", "_WIN32_WINNT=0x0A00", "WINVER=0x0A00", "WINNT=1", "NTDDI_VERSION=0x0A000004", "_WINDLL")
    target:add("defines", "KMDF_VERSION_MAJOR=" .. kmdfver[1], "KMDF_VERSION_MINOR=" .. kmdfver[2], "KMDF_USING_NTSTATUS")

    -- add include directories
    target:add("includedirs", path.join(wdk.includedir, wdk.sdkver, "km"))
    target:add("includedirs", path.join(wdk.includedir, "wdf", "kmdf", wdk.kmdfver))

    -- add link directories
    target:add("linkdirs", path.join(wdk.libdir, wdk.sdkver, "km", arch))
    target:add("linkdirs", path.join(wdk.libdir, "wdf", "kmdf", arch, wdk.kmdfver))

    -- add links
    target:add("links", "BufferOverflowFastFailK", "ntoskrnl", "hal", "wmilib", "WdfLdr", "ntstrsafe", "wdmsec")

    -- compile as kernel driver
    target:add("cxflags", "-kernel", {force = true})
    target:add("ldflags", "-kernel", "-driver", {force = true})

    -- set subsystem: native, TODO 10.00
    target:add("ldflags", "-subsystem:native,10.00", {force = true})

    -- set default driver entry if does not exist
    local entry = false
    for _, ldflag in ipairs(target:get("ldflags")) do
        ldflag = ldflag:lower()
        if ldflag:find("[/%-]entry:") then
            entry = true
            break
        end
    end
    if not entry then
        target:add("links", "WdfDriverEntry")
        target:add("ldflags", "-entry:FxDriverEntry" .. (is_arch("x86") and "@8" or ""), {force = true})
    end
end

-- load for kmdf binary
function kmdf_binary(target)

    -- get wdk
    local wdk = target:data("wdk")

    -- set kind
    target:set("kind", "binary")

    -- add defines
    local arch = config.arch()
    local kmdfver = wdk.kmdfver:split('%.')
    if arch == "x64" then
        target:add("defines", "_WIN64", "_AMD64_", "AMD64")
    else
        target:add("defines", "_X86_=1", "i386=1", "STD_CALL")
    end
    target:add("defines", "WIN32_LEAN_AND_MEAN=1", "_WIN32_WINNT=0x0A00", "WINVER=0x0A00", "WINNT=1", "NTDDI_VERSION=0x0A000004", "_WINDLL")
    target:add("defines", "KMDF_VERSION_MAJOR=" .. kmdfver[1], "KMDF_VERSION_MINOR=" .. kmdfver[2])

    -- add include directories
    target:add("includedirs", path.join(wdk.includedir, wdk.sdkver, "km"))
    target:add("includedirs", path.join(wdk.includedir, "wdf", "kmdf", wdk.kmdfver))

    -- add link directories
    target:add("linkdirs", path.join(wdk.libdir, wdk.sdkver, "km", arch))
    target:add("linkdirs", path.join(wdk.libdir, "wdf", "kmdf", arch, wdk.kmdfver))

    -- add links
    target:add("links", "kernel32", "user32", "gdi32", "winspool", "comdlg32")
    target:add("links", "advapi32", "shell32", "ole32", "oleaut32", "uuid", "odbc32", "odbccp32", "setupapi")
end

-- load for wdm driver
function wdm_driver(target)

    -- get wdk
    local wdk = target:data("wdk")

    -- set kind
    target:set("kind", "binary")

    -- set filename: xxx.sys
    target:set("filename", target:basename() .. ".sys")

    -- add defines
    local arch = config.arch()
    local kmdfver = wdk.kmdfver:split('%.')
    if arch == "x64" then
        target:add("defines", "_WIN64", "_AMD64_", "AMD64")
    else
        target:add("cxflags", "-Gz", {force = true})
        target:add("defines", "_X86_=1", "i386=1", "STD_CALL")
    end
    target:add("defines", "WIN32_LEAN_AND_MEAN=1", "_WIN32_WINNT=0x0A00", "WINVER=0x0A00", "WINNT=1", "NTDDI_VERSION=0x0A000004", "_WINDLL")
    target:add("defines", "KMDF_VERSION_MAJOR=" .. kmdfver[1], "KMDF_VERSION_MINOR=" .. kmdfver[2], "KMDF_USING_NTSTATUS")

    -- add include directories
    target:add("includedirs", path.join(wdk.includedir, wdk.sdkver, "km"))
    target:add("includedirs", path.join(wdk.includedir, "wdf", "kmdf", wdk.kmdfver))

    -- add link directories
    target:add("linkdirs", path.join(wdk.libdir, wdk.sdkver, "km", arch))
    target:add("linkdirs", path.join(wdk.libdir, "wdf", "kmdf", arch, wdk.kmdfver))

    -- add links
    target:add("links", "BufferOverflowFastFailK", "ntoskrnl", "hal", "wmilib", "ntstrsafe")

    -- compile as kernel driver
    target:add("cxflags", "-kernel", {force = true})
    target:add("ldflags", "-kernel", "-driver", {force = true})

    -- set subsystem: native, TODO 10.00
    target:add("ldflags", "-subsystem:native,10.00", {force = true})

    -- set default driver entry if does not exist
    local entry = false
    for _, ldflag in ipairs(target:get("ldflags")) do
        ldflag = ldflag:lower()
        if ldflag:find("[/%-]entry:") then
            entry = true
            break
        end
    end
    if not entry then
        target:add("ldflags", "-entry:GsDriverEntry" .. (is_arch("x86") and "@8" or ""), {force = true})
    end
end

-- load for wdm binary
function wdm_binary(target)

    -- get wdk
    local wdk = target:data("wdk")

    -- set kind
    target:set("kind", "binary")

    -- add defines
    local arch = config.arch()
    local kmdfver = wdk.kmdfver:split('%.')
    if arch == "x64" then
        target:add("defines", "_WIN64", "_AMD64_", "AMD64")
    else
        target:add("defines", "_X86_=1", "i386=1", "STD_CALL")
    end
    target:add("defines", "WIN32_LEAN_AND_MEAN=1", "_WIN32_WINNT=0x0A00", "WINVER=0x0A00", "WINNT=1", "NTDDI_VERSION=0x0A000004", "_WINDLL")
    target:add("defines", "KMDF_VERSION_MAJOR=" .. kmdfver[1], "KMDF_VERSION_MINOR=" .. kmdfver[2])

    -- add include directories
    target:add("includedirs", path.join(wdk.includedir, wdk.sdkver, "km"))
    target:add("includedirs", path.join(wdk.includedir, "wdf", "kmdf", wdk.kmdfver))

    -- add link directories
    target:add("linkdirs", path.join(wdk.libdir, wdk.sdkver, "km", arch))
    target:add("linkdirs", path.join(wdk.libdir, "wdf", "kmdf", arch, wdk.kmdfver))

    -- add links
    target:add("links", "kernel32", "user32", "gdi32", "winspool", "comdlg32")
    target:add("links", "advapi32", "shell32", "ole32", "oleaut32", "uuid", "odbc32", "odbccp32", "setupapi")
end
