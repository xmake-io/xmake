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
-- @file        find_hdk.lua
--

-- imports
import("core.base.option")
import("core.base.global")
import("core.project.config")
import("core.cache.detectcache")
import("lib.detect.find_directory")

-- find hdk directory
function _find_hdkdir(sdkdir)

    -- get hdk directory
    if not sdkdir then
        if not sdkdir then
            if is_host("macosx") then
                local paths = {
                    "~/Library/OpenHarmony/Sdk/*",
                    "~/Library/Huawei/Sdk/*/*" -- for old version, deprecated
                }
                sdkdir = find_directory("native", paths)
            elseif is_host("windows") then
                sdkdir = find_directory("native", "~/Huawei/Sdk/*/*")
            end
        end
    end

    -- get hdk directory
    if sdkdir and os.isdir(sdkdir) then
        return path.translate(sdkdir)
    end
end

-- find the hdk toolchain
function _find_hdk(sdkdir)

    -- find hdk root directory
    sdkdir = _find_hdkdir(sdkdir)
    if not sdkdir then
        return
    end

    -- get the binary directory
    local bindir = path.join(sdkdir, "llvm", "bin")
    if not os.isdir(bindir) then
        return
    end

    local sysroot = path.join(sdkdir, "sysroot")
    return {sdkdir = sdkdir,
            bindir = bindir,
            sysroot = sysroot}
end

-- find hdk toolchains
--
-- @param sdkdir    the hdk directory
-- @param opt       the argument options
--                  e.g. {verbose = true, force = false}
--
-- @return          the hdk toolchains. e.g. {bindir = .., cross = ..}
--
-- @code
--
-- local toolchain = find_hdk("/xxx/android-hdk-r10e")
--
-- @endcode
--
function main(sdkdir, opt)
    opt = opt or {}

    -- attempt to load cache first
    local key = "detect.sdks.find_hdk"
    local cacheinfo = detectcache:get(key) or {}
    if not opt.force and cacheinfo.hdk and cacheinfo.hdk.sdkdir and os.isdir(cacheinfo.hdk.sdkdir) then
        return cacheinfo.hdk
    end

    -- find hdk
    local hdk = _find_hdk(sdkdir or config.get("sdk") or global.get("sdk"))
    if hdk and hdk.sdkdir then
        config.set("hdk", hdk.sdkdir, {force = true, readonly = true})
        if opt.verbose or option.get("verbose") then
            cprint("checking for Harmony SDK directory ... ${color.success}%s", hdk.sdkdir)
        end
    else
        if opt.verbose or option.get("verbose") then
            cprint("checking for Harmony SDK directory ... ${color.nothing}${text.nothing}")
        end
    end

    -- save to cache
    cacheinfo.hdk = hdk or false
    detectcache:set(key, cacheinfo)
    detectcache:save()
    return hdk
end
