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
import("utils.os.winver", {alias = "os_winver"})

-- get windows version value
function _winver(winver)
    return os_winver.value(winver or "") or "0x0A00"
end

-- get windows ntddi version value
function _winver_ntddi(winver)
    return os_winver.value_ntddi(winver or "") or "0x0A000000"
end

-- get subsystem version defined value
function _winver_subsystem(winver)

    -- ignore the subname with '_xxx'
    winver = (winver or ""):split('_')[1]

    -- make defined values
    local defvals = 
    {
        win10   = "10.00" 
    ,   win81   = "6.03" 
    ,   winblue = "6.03"  
    ,   win8    = "6.02"
    ,   win7    = "6.01" 
    }
    return defvals[winver] or "10.00"
end

-- get version of the library sub-directory 
function _winver_libdir(winver)

    -- ignore the subname with '_xxx'
    winver = (winver or ""):split('_')[1]

    -- make defined values
    local vervals = 
    {
        win81   = "winv6.3" 
    ,   winblue = "winv6.3" 
    ,   win8    = "win8"  
    ,   win7    = "win7"  
    }
    return vervals[winver] 
end

-- load for umdf driver
function umdf_driver(target)

    -- get wdk
    local wdk = target:data("wdk")

    -- get arch
    local arch = config.arch()

    -- set kind
    target:set("kind", "shared")

    -- add defines
    local winver  = target:values("wdk.env.winver") or config.get("wdk_winver")
    local umdfver = wdk.umdfver:split('%.')
    if arch == "x64" then
        target:add("defines", "_WIN64", "_AMD64_", "AMD64")
    else
        target:add("cxflags", "-Gz", {force = true})
        target:add("defines", "_X86_=1", "i386=1", "STD_CALL")
        target:add("defines", "DEPRECATE_DDK_FUNCTIONS=1", "MSC_NOOPT", "_ATL_NO_WIN_SUPPORT", "_WINDLL")
    end
    target:add("defines", "UMDF_VERSION_MAJOR=" .. umdfver[1], "UMDF_VERSION_MINOR=" .. umdfver[2], "UMDF_USING_NTSTATUS")
    target:add("defines", "WIN32_LEAN_AND_MEAN=1", "WINNT=1", "_WINDLL")
    target:add("defines", "_WIN32_WINNT=" .. _winver(winver), "WINVER=" .. _winver(winver), "NTDDI_VERSION=" .. _winver_ntddi(winver))

    -- add include directories
    target:add("includedirs", path.join(wdk.includedir, wdk.sdkver, "um"))
    target:add("includedirs", path.join(wdk.includedir, "wdf", "umdf", wdk.umdfver))

    -- add link directories
    target:add("linkdirs", path.join(wdk.libdir, wdk.sdkver, "um", arch))
    target:add("linkdirs", path.join(wdk.libdir, "wdf", "umdf", arch, wdk.umdfver))

    -- add links
    target:add("links", "ntdll", "OneCoreUAP", "mincore", "ucrt")
    target:add("shflags", "-NODEFAULTLIB:kernel32.lib", "-NODEFAULTLIB:user32.lib", "-NODEFAULTLIB:libucrt.lib", {force = true})

    -- add subsystem
    target:add("shflags", "-subsystem:windows," .. _winver_subsystem(winver), {force = true})

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

    -- get arch
    local arch = config.arch()

    -- set kind
    target:set("kind", "binary")

    -- add defines
    local winver  = target:values("wdk.env.winver") or config.get("wdk_winver")
    if arch == "x64" then
        target:add("defines", "_WIN64", "_AMD64_", "AMD64")
    else
        target:add("defines", "_X86_=1", "i386=1", "STD_CALL")
        target:add("defines", "_ATL_NO_WIN_SUPPORT", "_CRT_USE_WINAPI_PARTITION_APP")
    end
    target:add("defines", "WIN32_LEAN_AND_MEAN=1", "WINNT=1", "_WINDLL")
    target:add("defines", "_WIN32_WINNT=" .. _winver(winver), "WINVER=" .. _winver(winver), "NTDDI_VERSION=" .. _winver_ntddi(winver))

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

    -- get arch
    local arch = config.arch()

    -- set kind
    target:set("kind", "binary")

    -- set filename: xxx.sys
    target:set("filename", target:basename() .. ".sys")

    -- add defines
    local winver  = target:values("wdk.env.winver") or config.get("wdk_winver")
    local kmdfver = wdk.kmdfver:split('%.')
    if arch == "x64" then
        target:add("defines", "_WIN64", "_AMD64_", "AMD64")
    else
        target:add("cxflags", "-Gz", {force = true})
        target:add("defines", "_X86_=1", "i386=1", "STD_CALL")
    end
    target:add("defines", "KMDF_VERSION_MAJOR=" .. kmdfver[1], "KMDF_VERSION_MINOR=" .. kmdfver[2], "KMDF_USING_NTSTATUS")
    target:add("defines", "WIN32_LEAN_AND_MEAN=1", "WINNT=1", "_WINDLL")
    target:add("defines", "_WIN32_WINNT=" .. _winver(winver), "WINVER=" .. _winver(winver), "NTDDI_VERSION=" .. _winver_ntddi(winver))

    -- add include directories
    target:add("includedirs", path.join(wdk.includedir, wdk.sdkver, "km"))
    target:add("includedirs", path.join(wdk.includedir, wdk.sdkver, "km", "crt"))
    target:add("includedirs", path.join(wdk.includedir, "wdf", "kmdf", wdk.kmdfver))

    -- add link directories
    local libdirver = _winver_libdir(winver)
    if libdirver then
        target:add("linkdirs", path.join(wdk.libdir, libdirver, "km", arch))
    end
    target:add("linkdirs", path.join(wdk.libdir, wdk.sdkver, "km", arch))
    target:add("linkdirs", path.join(wdk.libdir, "wdf", "kmdf", arch, wdk.kmdfver))

    -- add links
    target:add("links", "BufferOverflowFastFailK", "ntoskrnl", "hal", "wmilib", "WdfLdr", "ntstrsafe", "wdmsec")

    -- compile as kernel driver
    target:add("cxflags", "-kernel", {force = true})
    target:add("ldflags", "-kernel", "-driver", {force = true})

    -- add subsystem    
    target:add("ldflags", "-subsystem:native," .. _winver_subsystem(winver), {force = true})

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

    -- get arch
    local arch = config.arch()

    -- set kind
    target:set("kind", "binary")

    -- add defines
    local winver  = target:values("wdk.env.winver") or config.get("wdk_winver")
    local kmdfver = wdk.kmdfver:split('%.')
    if arch == "x64" then
        target:add("defines", "_WIN64", "_AMD64_", "AMD64")
    else
        target:add("defines", "_X86_=1", "i386=1", "STD_CALL")
    end
    target:add("defines", "KMDF_VERSION_MAJOR=" .. kmdfver[1], "KMDF_VERSION_MINOR=" .. kmdfver[2])
    target:add("defines", "WIN32_LEAN_AND_MEAN=1", "WINNT=1", "_WINDLL")
    target:add("defines", "_WIN32_WINNT=" .. _winver(winver), "WINVER=" .. _winver(winver), "NTDDI_VERSION=" .. _winver_ntddi(winver))

    -- add include directories
    target:add("includedirs", path.join(wdk.includedir, wdk.sdkver, "km"))
    target:add("includedirs", path.join(wdk.includedir, "wdf", "kmdf", wdk.kmdfver))

    -- add link directories
    local libdirver = _winver_libdir(winver)
    if libdirver then
        target:add("linkdirs", path.join(wdk.libdir, libdirver, "km", arch))
    end
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

    -- get arch
    local arch = config.arch()

    -- set kind
    target:set("kind", "binary")

    -- set filename: xxx.sys
    target:set("filename", target:basename() .. ".sys")

    -- add defines
    local winver  = target:values("wdk.env.winver") or config.get("wdk_winver")
    local kmdfver = wdk.kmdfver:split('%.')
    if arch == "x64" then
        target:add("defines", "_WIN64", "_AMD64_", "AMD64")
    else
        target:add("cxflags", "-Gz", {force = true})
        target:add("defines", "_X86_=1", "i386=1", "STD_CALL")
    end
    target:add("defines", "KMDF_VERSION_MAJOR=" .. kmdfver[1], "KMDF_VERSION_MINOR=" .. kmdfver[2], "KMDF_USING_NTSTATUS")
    target:add("defines", "WIN32_LEAN_AND_MEAN=1", "WINNT=1", "_WINDLL")
    target:add("defines", "_WIN32_WINNT=" .. _winver(winver), "WINVER=" .. _winver(winver), "NTDDI_VERSION=" .. _winver_ntddi(winver))

    -- add include directories
    target:add("includedirs", path.join(wdk.includedir, wdk.sdkver, "km"))
    target:add("includedirs", path.join(wdk.includedir, wdk.sdkver, "km", "crt"))
    target:add("includedirs", path.join(wdk.includedir, "wdf", "kmdf", wdk.kmdfver))

    -- add link directories
    local libdirver = _winver_libdir(winver)
    if libdirver then
        target:add("linkdirs", path.join(wdk.libdir, libdirver, "km", arch))
    end
    target:add("linkdirs", path.join(wdk.libdir, wdk.sdkver, "km", arch))
    target:add("linkdirs", path.join(wdk.libdir, "wdf", "kmdf", arch, wdk.kmdfver))

    -- add links
    target:add("links", "BufferOverflowFastFailK", "ntoskrnl", "hal", "wmilib", "ntstrsafe")

    -- compile as kernel driver
    target:add("cxflags", "-kernel", {force = true})
    target:add("ldflags", "-kernel", "-driver", {force = true})

    -- add subsystem    
    target:add("ldflags", "-subsystem:native," .. _winver_subsystem(winver), {force = true})

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

    -- get arch
    local arch = config.arch()

    -- set kind
    target:set("kind", "binary")

    -- add defines
    local winver  = target:values("wdk.env.winver") or config.get("wdk_winver")
    local kmdfver = wdk.kmdfver:split('%.')
    if arch == "x64" then
        target:add("defines", "_WIN64", "_AMD64_", "AMD64")
    else
        target:add("defines", "_X86_=1", "i386=1", "STD_CALL")
    end
    target:add("defines", "KMDF_VERSION_MAJOR=" .. kmdfver[1], "KMDF_VERSION_MINOR=" .. kmdfver[2])
    target:add("defines", "WIN32_LEAN_AND_MEAN=1", "WINNT=1", "_WINDLL")
    target:add("defines", "_WIN32_WINNT=" .. _winver(winver), "WINVER=" .. _winver(winver), "NTDDI_VERSION=" .. _winver_ntddi(winver))

    -- add include directories
    target:add("includedirs", path.join(wdk.includedir, wdk.sdkver, "km"))
    target:add("includedirs", path.join(wdk.includedir, "wdf", "kmdf", wdk.kmdfver))

    -- add link directories
    local libdirver = _winver_libdir(winver)
    if libdirver then
        target:add("linkdirs", path.join(wdk.libdir, libdirver, "km", arch))
    end
    target:add("linkdirs", path.join(wdk.libdir, wdk.sdkver, "km", arch))
    target:add("linkdirs", path.join(wdk.libdir, "wdf", "kmdf", arch, wdk.kmdfver))

    -- add links
    target:add("links", "kernel32", "user32", "gdi32", "winspool", "comdlg32")
    target:add("links", "advapi32", "shell32", "ole32", "oleaut32", "uuid", "odbc32", "odbccp32", "setupapi")
end
