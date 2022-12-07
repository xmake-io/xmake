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
-- @author      SirLynix
-- @file        find_emscripten.lua
--

-- imports
import("core.base.semver")
import("core.base.option")
import("core.base.global")
import("core.project.config")
import("core.cache.detectcache")
import("lib.detect.find_file")
import("detect.sdks.find_emsdk")

-- find emscripten directory
function _find_emscriptendir(sdkdir)

    -- try to find emcc (compiler script)
    local paths = {}
    if sdkdir then
        table.insert(paths, sdkdir)
    end
    table.insert(paths, function ()
        local emsdk = find_emsdk(sdkdir)
        if emsdk then
            return emsdk.sdkdir
        end
    end)

    local subdirs = {}
    table.insert(subdirs, path.join("upstream", "emscripten"))

    local emcc = find_file("emcc", paths, {suffixes = subdirs})

    -- get sdk directory
    if emcc then
        return path.directory(emcc)
    end

end

-- find emscripten
function _find_emscripten(sdkdir)

    -- find emscripten directory
    sdkdir = _find_emscriptendir(sdkdir)
    if not sdkdir then
        return {}
    end

    -- ok?
    return {sdkdir = sdkdir}
end

-- find emscripten directory
--
-- @param sdkdir    the emscripten directory
-- @param opt       the argument options, e.g. {force = true}
--
-- @return          the sdk toolchains. e.g. {sdkdir = ..}
--
-- @code
--
-- local sdk = find_emscripten("~/emsdk/upstream/emscripten")
--
-- @endcode
--
function main(sdkdir, opt)

    -- init arguments
    opt = opt or {}

    -- attempt to load cache first
    local key = "detect.sdks.find_emscripten"
    local cacheinfo = detectcache:get(key) or {}
    if not opt.force and cacheinfo.sdk and cacheinfo.sdk.sdkdir and os.isdir(cacheinfo.sdk.sdkdir) then
        return cacheinfo.sdk
    end

    -- find sdk
    local sdk = _find_emscripten(sdkdir or config.get("emscripten") or global.get("emscripten"))
    if sdk and sdk.sdkdir then

        -- save to config
        config.set("emscripten", sdk.sdkdir, {force = true, readonly = true})

        -- trace
        if opt.verbose or option.get("verbose") then
            cprint("checking for emscripten toolchain directory ... ${color.success}%s", sdk.sdkdir)
        end

    else

        -- trace
        if opt.verbose or option.get("verbose") then
            cprint("checking for emscripten toolchain directory ... ${color.nothing}${text.nothing}")
        end
    end

    -- save to cache
    cacheinfo.sdk = sdk or false
    detectcache:set(key, cacheinfo)
    detectcache:save()
    return sdk
end
