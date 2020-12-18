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

-- load for umdf environment
function umdf(target)

    -- get wdk
    local wdk = target:data("wdk")

    -- get arch
    local arch = config.arch()

    -- add defines
    local umdfver = wdk.umdfver:split('%.')
    if arch == "x64" then
        target:add("defines", "_WIN64", "_AMD64_", "AMD64")
    else
        target:add("defines", "_X86_=1", "i386=1")
        target:add("defines", "DEPRECATE_DDK_FUNCTIONS=1", "MSC_NOOPT", "_ATL_NO_WIN_SUPPORT")
        target:add("defines", "STD_CALL")
        target:add("cxflags", "-Gz", {force = true})
    end
    target:add("defines", "UMDF_VERSION_MAJOR=" .. umdfver[1], "UMDF_VERSION_MINOR=" .. umdfver[2], "UMDF_USING_NTSTATUS")
    target:add("defines", "WIN32_LEAN_AND_MEAN=1", "WINNT=1", "_WINDLL")

    -- add include directories
    target:add("includedirs", path.join(wdk.includedir, wdk.sdkver, "um"))
    target:add("includedirs", path.join(wdk.includedir, "wdf", "umdf", wdk.umdfver))

    -- add link directories
    target:add("linkdirs", path.join(wdk.libdir, wdk.sdkver, "um", arch))
    target:add("linkdirs", path.join(wdk.libdir, "wdf", "umdf", arch, wdk.umdfver))
end

-- load for kmdf environment
function kmdf(target)

    -- get wdk
    local wdk = target:data("wdk")

    -- get arch
    local arch = config.arch()

    -- add defines
    local winver  = target:values("wdk.env.winver") or config.get("wdk_winver")
    local kmdfver = wdk.kmdfver:split('%.')
    if arch == "x64" then
        target:add("defines", "_WIN64", "_AMD64_", "AMD64")
    else
        target:add("defines", "_X86_=1", "i386=1")
        target:add("defines", "DEPRECATE_DDK_FUNCTIONS=1", "MSC_NOOPT", "_ATL_NO_WIN_SUPPORT")
        target:add("defines", "STD_CALL")
        target:add("cxflags", "-Gz", {force = true})
    end
    target:add("defines", "KMDF_VERSION_MAJOR=" .. kmdfver[1], "KMDF_VERSION_MINOR=" .. kmdfver[2], "KMDF_USING_NTSTATUS")
    target:add("defines", "WIN32_LEAN_AND_MEAN=1", "WINNT=1", "_WINDLL")

    -- add include directories
    target:add("includedirs", path.join(wdk.includedir, wdk.sdkver, "km"))
    if target:rule("wdk.driver") then
        target:add("includedirs", path.join(wdk.includedir, wdk.sdkver, "km", "crt"))
    end
    target:add("includedirs", path.join(wdk.includedir, "wdf", "kmdf", wdk.kmdfver))

    -- add link directories
    local libdirver = _winver_libdir(winver)
    if libdirver then
        target:add("linkdirs", path.join(wdk.libdir, libdirver, "km", arch))
    end
    target:add("linkdirs", path.join(wdk.libdir, wdk.sdkver, "km", arch))
    target:add("linkdirs", path.join(wdk.libdir, "wdf", "kmdf", arch, wdk.kmdfver))
end

-- load for wdm environment
function wdm(target)

    -- get wdk
    local wdk = target:data("wdk")

    -- get arch
    local arch = config.arch()

    -- add defines
    local winver  = target:values("wdk.env.winver") or config.get("wdk_winver")
    local kmdfver = wdk.kmdfver:split('%.')
    if arch == "x64" then
        target:add("defines", "_WIN64", "_AMD64_", "AMD64")
    else
        target:add("defines", "_X86_=1", "i386=1")
        target:add("defines", "DEPRECATE_DDK_FUNCTIONS=1", "MSC_NOOPT", "_ATL_NO_WIN_SUPPORT")
        target:add("defines", "STD_CALL")
        target:add("cxflags", "-Gz", {force = true})
    end
    target:add("defines", "KMDF_VERSION_MAJOR=" .. kmdfver[1], "KMDF_VERSION_MINOR=" .. kmdfver[2], "KMDF_USING_NTSTATUS")
    target:add("defines", "WIN32_LEAN_AND_MEAN=1", "WINNT=1", "_WINDLL")

    -- add include directories
    target:add("includedirs", path.join(wdk.includedir, wdk.sdkver, "km"))
    if target:rule("wdk.driver") then
        target:add("includedirs", path.join(wdk.includedir, wdk.sdkver, "km", "crt"))
    end
    target:add("includedirs", path.join(wdk.includedir, "wdf", "kmdf", wdk.kmdfver))

    -- add link directories
    local libdirver = _winver_libdir(winver)
    if libdirver then
        target:add("linkdirs", path.join(wdk.libdir, libdirver, "km", arch))
    end
    target:add("linkdirs", path.join(wdk.libdir, wdk.sdkver, "km", arch))
    target:add("linkdirs", path.join(wdk.libdir, "wdf", "kmdf", arch, wdk.kmdfver))
end
