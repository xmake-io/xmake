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
-- @file        find_masm32.lua
--

-- imports
import("lib.detect.find_path")
import("core.base.option")
import("core.project.config")
import("core.cache.detectcache")

-- find masm32 directory
function _find_sdkdir(sdkdir)
    local paths = {}
    if sdkdir then
        table.insert(paths, path.join(sdkdir, "bin"))
    else
        for _, logical_drive in ipairs(winos.logical_drives()) do
            table.insert(paths, path.join(logical_drive, "masm32", "bin"))
        end
    end
    local bindir = find_path("ml.exe", paths)
    if bindir then
        return path.directory(bindir)
    end
end

-- find masm32 toolchains
function _find_masm32(sdkdir)
    sdkdir = _find_sdkdir(sdkdir)
    if not sdkdir or not os.isdir(sdkdir) then
        return
    end
    return {sdkdir = sdkdir, bindir = path.join(sdkdir, "bin"), includedir = path.join(sdkdir, "include"), libdir = path.join(sdkdir, "lib")}
end

-- find masm32 toolchains
--
-- @param sdkdir    the masm32 directory
-- @param opt       the argument options, e.g. {verbose = true, force = false}
--
-- @return          the masm32 toolchains. e.g. {sdkver = ..., sdkdir, sdkdir_armcc, sdkdir_armclang}
--
-- @code
--
-- local toolchains = find_masm32("~/masm32")
--
-- @endcode
--
function main(sdkdir, opt)

    -- init arguments
    opt = opt or {}

    -- attempt to load cache first
    local key = "detect.sdks.find_masm32"
    local cacheinfo = detectcache:get(key) or {}
    if not opt.force and cacheinfo.masm32 and cacheinfo.masm32.sdkdir and os.isdir(cacheinfo.masm32.sdkdir) then
        return cacheinfo.masm32
    end

    -- find masm32
    local masm32 = _find_masm32(sdkdir or config.get("sdk"))
    if masm32 then
        if opt.verbose or option.get("verbose") then
            cprint("checking for masm32 directory ... ${color.success}%s", masm32.sdkdir)
        end
    else
        if opt.verbose or option.get("verbose") then
            cprint("checking for masm32 directory ... ${color.nothing}${text.nothing}")
        end
    end

    -- save to cache
    cacheinfo.masm32 = masm32 or false
    detectcache:set(key, cacheinfo)
    detectcache:save()
    return masm32
end
