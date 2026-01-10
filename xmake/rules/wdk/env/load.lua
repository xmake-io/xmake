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

function _base(target, mode)

    -- get wdk
    local wdk = target:data("wdk")

    -- get arch
    local arch = config.arch()

    -- add definitions
    local ver = mode == "um" and wdk.umdfver or wdk.kmdfver
    local ver_split = ver:split('%.')
    if arch == "x64" then
        target:add("defines", "_WIN64", "_AMD64_", "AMD64")
    else
        target:add("defines", "_X86_=1", "i386=1")
        target:add("defines", "DEPRECATE_DDK_FUNCTIONS=1", "MSC_NOOPT", "_ATL_NO_WIN_SUPPORT")
        target:add("defines", "STD_CALL")
        target:add("cxflags", "-Gz", {force = true})
    end

    local prefix = mode == "um" and "UM" or "KM"
    target:add("defines", prefix .. "DF_VERSION_MAJOR=" .. ver_split[1], prefix .. "DF_VERSION_MINOR=" .. ver_split[2], prefix .. "DF_USING_NTSTATUS")
    target:add("defines", "WIN32_LEAN_AND_MEAN=1", "WINNT=1", "_WINDLL")

    -- add include directories
    target:add("sysincludedirs", path.join(wdk.includedir, wdk.sdkver, mode))
    target:add("sysincludedirs", path.join(wdk.includedir, "wdf", mode .. "df", ver))

    -- add link directories
    target:add("linkdirs", path.join(wdk.libdir, wdk.sdkver, mode, arch))
    local p = path.join(wdk.libdir, "wdf", mode .. "df", arch, ver)
    if os.isdir(p) then
        target:add("linkdirs", p)
    end
end

-- load for umdf environment
function umdf(target)

    _base(target, "um")
end

-- load for kmdf environment
function kmdf(target)

    -- get wdk
    local wdk = target:data("wdk")

    -- get arch
    local arch = config.arch()

    -- add definitions
    local winver  = target:values("wdk.env.winver") or config.get("wdk_winver")

    _base(target, "km")

    -- add include directories
    target:add("sysincludedirs", path.join(wdk.includedir, wdk.sdkver, "shared"))
    if target:rule("wdk.driver") then
        target:add("sysincludedirs", path.join(wdk.includedir, wdk.sdkver, "km", "crt"))
    end

    -- add link directories
    local libdirver = _winver_libdir(winver)
    if libdirver then
        target:add("linkdirs", path.join(wdk.libdir, libdirver, "km", arch))
    end
end

-- load for wdm environment
function wdm(target)

    kmdf(target)
end
