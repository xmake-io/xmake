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
-- Copyright (C) 2015 - 2019, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        find_android_sdk.lua
--

-- imports
import("lib.detect.cache")
import("core.base.option")
import("core.base.global")
import("core.project.config")
import("lib.detect.find_directory")

-- find sdk directory
function _find_android_sdkdir(sdkdir)

    -- get sdk directory
    if not sdkdir then
        sdkdir = os.getenv("ANDROID_SDK_ROOT")
        if not sdkdir and is_host("macosx") then
            sdkdir = "~/Library/Android/sdk"
        end
    end

    -- get sdk directory
    if sdkdir and os.isdir(sdkdir) then
        return sdkdir
    end
end

-- find the android sdk 
function _find_android_sdk(sdkdir)

    -- find sdk root directory
    sdkdir = _find_android_sdkdir(sdkdir)
    if not sdkdir then
        return {}
    end

    -- ok?    
    return {sdkdir = sdkdir}
end

-- find android sdk directory
--
-- @param sdkdir    the android sdk directory
-- @param opt       the argument options, e.g. {force = true} 
--
-- @return          the sdk toolchains. .e.g {sdkdir = ..}
--
-- @code 
--
-- local sdk = find_android_sdk("~/Library/Android/sdk")
-- 
-- @endcode
--
function main(sdkdir, opt)

    -- init arguments
    opt = opt or {}

    -- attempt to load cache first
    local key = "detect.sdks.find_android_sdk"
    local cacheinfo = cache.load(key)
    if not opt.force and cacheinfo.sdk and cacheinfo.sdk.sdkdir and os.isdir(cacheinfo.sdk.sdkdir) then
        return cacheinfo.sdk
    end

    -- find sdk
    local sdk = _find_android_sdk(sdkdir or config.get("android_sdk") or global.get("android_sdk"))
    if sdk and sdk.sdkdir then

        -- save to config
        config.set("android_sdk", sdk.sdkdir, {force = true, readonly = true})

        -- trace
        if opt.verbose or option.get("verbose") then
            cprint("checking for the Android SDK directory ... ${color.success}%s", sdk.sdkdir)
        end
    else

        -- trace
        if opt.verbose or option.get("verbose") then
            cprint("checking for the Android SDK directory ... ${color.nothing}${text.nothing}")
        end
    end

    -- save to cache
    cacheinfo.sdk = sdk or false
    cache.save(key, cacheinfo)

    -- ok?
    return sdk
end
