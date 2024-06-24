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
-- @file        find_mdk.lua
--

-- imports
import("lib.detect.find_path")
import("core.base.option")
import("core.base.semver")
import("core.project.config")
import("core.cache.detectcache")

-- find MDK directory
function _find_sdkdir(sdkdir)
    local paths = {
        "$(reg HKEY_LOCAL_MACHINE\\SOFTWARE\\Wow6432Node\\Keil\\Products\\MDK;Path)"
    }
    if sdkdir then
        table.insert(paths, 1, sdkdir)
    end
    local result = find_path("armcc", paths) or find_path("armclang", paths)
    if not result then
        -- find it from some logical drives paths
        paths = {}
        for _, logical_drive in ipairs(winos.logical_drives()) do
            table.insert(paths, path.join(logical_drive, "Keil_v5", "ARM"))
        end
        result = find_path("armcc", paths) or find_path("armclang", paths)
    end
    return result
end

-- find MDK toolchains
function _find_mdk(sdkdir)

    -- find mdk directory
    sdkdir = _find_sdkdir(sdkdir)
    if not sdkdir or not os.isdir(sdkdir) then
        return nil
    end
    local result = {sdkdir = sdkdir}

    -- get sdk version
    local sdkver = winos.registry_query("HKEY_LOCAL_MACHINE\\SOFTWARE\\Wow6432Node\\Keil\\Products\\MDK;Version")
    if sdkver then
        sdkver = semver.match(sdkver, 1, "V%d+%.%d+")
        if sdkver then
            result.sdkver = sdkver:rawstr()
        end
    end

    -- armcc sdk directory
    local sdkdir_armcc = path.join(sdkdir, "armcc")
    if os.isdir(sdkdir_armcc) and os.isfile(path.join(sdkdir_armcc, "bin", "armcc.exe")) then
        result.sdkdir_armcc = sdkdir_armcc
    end

    -- armclang sdk directory
    local sdkdir_armclang = path.join(sdkdir, "armclang")
    if os.isdir(sdkdir_armclang) and os.isfile(path.join(sdkdir_armclang, "bin", "armclang.exe")) then
        result.sdkdir_armclang = sdkdir_armclang
    end
    return result
end

-- find MDK toolchains
--
-- @param sdkdir    the MDK directory
-- @param opt       the argument options, e.g. {verbose = true, force = false}
--
-- @return          the MDK toolchains. e.g. {sdkver = ..., sdkdir, sdkdir_armcc, sdkdir_armclang}
--
-- @code
--
-- local toolchains = find_mdk("~/mdk")
--
-- @endcode
--
function main(sdkdir, opt)

    -- init arguments
    opt = opt or {}

    -- attempt to load cache first
    local key = "detect.sdks.find_mdk"
    local cacheinfo = detectcache:get(key) or {}
    if not opt.force and cacheinfo.mdk and cacheinfo.mdk.sdkdir and os.isdir(cacheinfo.mdk.sdkdir) then
        return cacheinfo.mdk
    end

    -- find mdk
    local mdk = _find_mdk(sdkdir or config.get("sdk"))
    if mdk then
        if opt.verbose or option.get("verbose") then
            cprint("checking for MDK directory ... ${color.success}%s", mdk.sdkdir)
        end
    else
        if opt.verbose or option.get("verbose") then
            cprint("checking for MDK directory ... ${color.nothing}${text.nothing}")
        end
    end

    -- save to cache
    cacheinfo.mdk = mdk or false
    detectcache:set(key, cacheinfo)
    detectcache:save()
    return mdk
end
