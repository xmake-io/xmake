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
-- Based On template file xmake\modules\detect\sdks\find_mdk.lua
--
-- @author      DawnMagnet
-- @file        find_c51.lua
--

-- imports
import("lib.detect.find_path")
import("core.base.option")
import("core.base.semver")
import("core.project.config")
import("core.cache.detectcache")

-- find C51 directory
function _find_sdkdir(sdkdir)
    local paths = {
        "$(reg HKEY_LOCAL_MACHINE\\SOFTWARE\\Wow6432Node\\Keil\\Products\\C51;Path)"
    }
    if sdkdir then
        table.insert(paths, 1, sdkdir)
    end
    local result = find_path("..\\C51", paths)
    if not result then
        -- find it from some logical drives paths
        paths = {}
        for _, logical_drive in ipairs(winos.logical_drives()) do
            table.insert(paths, path.join(logical_drive, "Keil_v5", "C51", "BIN"))
        end
        result = find_path("C51.exe", paths)
    end
    return result
end

-- find C51 toolchains
function _find_c51(sdkdir)
    -- find C51 directory
    sdkdir = _find_sdkdir(sdkdir)
    if not sdkdir or not os.isdir(sdkdir) then
        return nil
    end
    local result = {sdkdir = sdkdir}

    -- get sdk version
    local sdkver = winos.registry_query("HKEY_LOCAL_MACHINE\\SOFTWARE\\Wow6432Node\\Keil\\Products\\C51;Version")
    if sdkver then
        sdkver = semver.match(sdkver, 1, "V%d+%.%d+")
        if sdkver then
            result.sdkver = sdkver:rawstr()
        end
    end

    -- c51(exe) sdk directory
    if os.isfile(path.join(sdkdir, "bin", "c51.exe")) then
        result.sdkdir_c51 = sdkdir
    end

    -- a51(exe) sdk directory
    if os.isfile(path.join(sdkdir, "bin", "a51.exe")) then
        result.sdkdir_a51 = sdkdir
    end
    return result
end

-- find c51 toolchains
--
-- @param sdkdir    the C51 directory
-- @param opt       the argument options, e.g. {verbose = true, force = false}
--
-- @return          the C51 toolchains. e.g. {sdkver = ..., sdkdir, sdkdir_armcc, sdkdir_armclang, sdkdir_c51}
--
-- @code
--
-- local toolchains = find_c51("~/c51")
--
-- @endcode
--
function main(sdkdir, opt)

    -- init arguments
    opt = opt or {}

    -- attempt to load cache first
    local key = "detect.sdks.find_c51"

    local cacheinfo = detectcache:get(key) or {}
    if not opt.force and cacheinfo.c51 and cacheinfo.c51.sdkdir and os.isdir(cacheinfo.c51.sdkdir) then
        return cacheinfo.c51
    end

    -- find c51
    local c51 = _find_c51(sdkdir or config.get("sdk"))
    if c51 then
        if opt.verbose or option.get("verbose") then
            cprint("checking for c51 directory ... ${color.success}%s", c51.sdkdir)
        end
    else
        if opt.verbose or option.get("verbose") then
            cprint("checking for c51 directory ... ${color.nothing}${text.nothing}")
        end
    end

    -- save to cache
    cacheinfo.c51 = c51 or false
    detectcache:set(key, cacheinfo)
    detectcache:save()
    return c51
end
