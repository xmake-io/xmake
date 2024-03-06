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
-- @author      vkensou
-- @file        find_wasisdk.lua
--

-- imports
import("core.base.semver")
import("core.base.option")
import("core.base.global")
import("core.project.config")
import("core.cache.detectcache")
import("lib.detect.find_file")

-- find wasm-ld directory
function _find_wasm_ld(sdkdir)
    local subdirs = {}
    table.insert(subdirs, "bin")

    local paths = {}
    if sdkdir then
        table.insert(paths, sdkdir)
    end
    table.insert(paths, "$(env WASI_SDK_PATH)")

    local wasm_ldname = (is_host("windows") and "wasm-ld.exe" or "wasm-ld")
    local wasm_ld = find_file(wasm_ldname, paths, {suffixes = subdirs})
    if wasm_ld then
        return path.directory(wasm_ld)
    end
end

-- find wasi-sdk
function _find_wasisdk(sdkdir)

    -- find bin directory
    local bindir = _find_wasm_ld(sdkdir)
    if not bindir or path.filename(bindir) ~= "bin" then
        return {}
    end

    -- find sdk root directory
    sdkdir = path.directory(bindir)
    if not sdkdir then
        return {}
    end

    return {sdkdir = sdkdir, bindir = bindir}
end

-- find wasi-sdk directory
--
-- @param sdkdir    the wasi-sdk directory
-- @param opt       the argument options, e.g. {force = true}
--
-- @return          the sdk toolchains. e.g. {sdkdir = ..}
--
-- @code
--
-- local sdk = find_wasisdk("~/wasi-sdk")
--
-- @endcode
--
function main(sdkdir, opt)
    opt = opt or {}

    -- attempt to load cache first
    local key = "detect.sdks.find_wasisdk"
    local cacheinfo = detectcache:get(key) or {}
    if not opt.force and cacheinfo.sdk and cacheinfo.sdk.sdkdir and os.isdir(cacheinfo.sdk.sdkdir) then
        return cacheinfo.sdk
    end

    -- find sdk
    local sdk = _find_wasisdk(sdkdir)
    if sdk and sdk.sdkdir and sdk.bindir then
        if opt.verbose or option.get("verbose") then
            cprint("checking for wasi-sdk directory ... ${color.success}%s", sdk.sdkdir)
        end
    else
        if opt.verbose or option.get("verbose") then
            cprint("checking for wasi-sdk directory ... ${color.nothing}${text.nothing}")
        end
    end

    -- save to cache
    cacheinfo.sdk = sdk or false
    detectcache:set(key, cacheinfo)
    detectcache:save()
    return sdk
end
