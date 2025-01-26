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
-- @file        find_iarsdk.lua
--

-- imports
import("lib.detect.find_path")
import("core.base.option")
import("core.base.semver")
import("core.project.config")
import("core.cache.detectcache")

-- find IAR sdk directory
function _find_sdkdir(sdkdir)
    local paths = {
        "$(reg HKEY_LOCAL_MACHINE\\SOFTWARE\\WOW6432Node\\IAR Systems\\Embedded Workbench\\5.0;LastInstallPath)/arm/bin"
    }
    if sdkdir then
        table.insert(paths, 1, sdkdir)
    end
    local bindir = find_path("iccarm.exe", paths)
    if bindir then
        return path.directory(bindir)
    end
end

-- find IAR sdk toolchains
function _find_iarsdk(sdkdir)

    -- find iarsdk directory
    sdkdir = _find_sdkdir(sdkdir)
    if not sdkdir or not os.isdir(sdkdir) then
        return nil
    end
    return {sdkdir = sdkdir}
end

-- find IAR sdk toolchains
--
-- @param sdkdir    the IAR sdk directory
-- @param opt       the argument options, e.g. {verbose = true, force = false}
--
-- @return          the IAR sdk toolchains. e.g. {sdkver = ..., sdkdir}
--
-- @code
--
-- local toolchains = find_iarsdk("~/iarsdk")
--
-- @endcode
--
function main(sdkdir, opt)

    -- init arguments
    opt = opt or {}

    -- attempt to load cache first
    local key = "detect.sdks.find_iarsdk"
    local cacheinfo = detectcache:get(key) or {}
    if not opt.force and cacheinfo.iarsdk and cacheinfo.iarsdk.sdkdir and os.isdir(cacheinfo.iarsdk.sdkdir) then
        return cacheinfo.iarsdk
    end

    -- find iarsdk
    local iarsdk = _find_iarsdk(sdkdir or config.get("sdk"))
    if iarsdk then
        if opt.verbose or option.get("verbose") then
            cprint("checking for IAR Embedded Workbench directory ... ${color.success}%s", iarsdk.sdkdir)
        end
    else
        if opt.verbose or option.get("verbose") then
            cprint("checking for IAR Embedded Workbench directory ... ${color.nothing}${text.nothing}")
        end
    end

    -- save to cache
    cacheinfo.iarsdk = iarsdk or false
    detectcache:set(key, cacheinfo)
    detectcache:save()
    return iarsdk
end
