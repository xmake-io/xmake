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
-- Copyright (C) 2015-2020, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        find_android_sdk.lua
--

-- imports
import("lib.detect.cache")
import("core.base.semver")
import("core.base.option")
import("core.base.global")
import("core.project.config")
import("lib.detect.find_directory")

-- find sdk directory
function _find_android_sdkdir(sdkdir)

    -- get sdk directory
    if not sdkdir then
        sdkdir = os.getenv("ANDROID_SDK_HOME") or os.getenv("ANDROID_SDK_ROOT")
        if not sdkdir and is_host("macosx") then
            sdkdir = "~/Library/Android/sdk"
        end
    end

    -- get sdk directory
    if sdkdir and os.isdir(sdkdir) then
        return sdkdir
    end
end

-- find the build-tools version of sdk
function _find_sdk_build_toolver(sdkdir)

    -- find the max version
    local toolver_max = "0"
    for _, dir in ipairs(os.dirs(path.join(sdkdir, "build-tools", "*"))) do
        local toolver = path.filename(dir)
        if semver.is_valid(toolver) and semver.compare(toolver, toolver_max) > 0 then
            toolver_max = toolver
        end
    end

    -- get the max sdk version
    return toolver_max ~= "0" and tostring(toolver_max) or nil
end

-- find the android sdk
function _find_android_sdk(sdkdir, build_toolver)

    -- find sdk root directory
    sdkdir = _find_android_sdkdir(sdkdir)
    if not sdkdir then
        return {}
    end

    -- find the build-tools version of sdk
    build_toolver = build_toolver or _find_sdk_build_toolver(sdkdir)

    -- ok?
    return {sdkdir = sdkdir, build_toolver = build_toolver}
end

-- find android sdk directory
--
-- @param sdkdir    the android sdk directory
-- @param opt       the argument options, e.g. {force = true, build_toolver = "28.0.3"}
--
-- @return          the sdk toolchains. e.g. {sdkdir = .., build_toolver = "28.0.3"}
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
    local sdk = _find_android_sdk(sdkdir or config.get("android_sdk") or global.get("android_sdk"), opt.build_toolver or config.get("build_toolver"))
    if sdk and sdk.sdkdir then

        -- save to config
        config.set("android_sdk", sdk.sdkdir, {force = true, readonly = true})
        config.set("build_toolver", sdk.build_toolver, {force = true, readonly = true})

        -- trace
        if opt.verbose or option.get("verbose") then
            cprint("checking for Android SDK directory ... ${color.success}%s", sdk.sdkdir)
            cprint("checking for Build Tools Version of Android SDK ... ${color.success}%s", sdk.build_toolver)
        end
    else

        -- trace
        if opt.verbose or option.get("verbose") then
            cprint("checking for Android SDK directory ... ${color.nothing}${text.nothing}")
        end
    end

    -- save to cache
    cacheinfo.sdk = sdk or false
    cache.save(key, cacheinfo)

    -- ok?
    return sdk
end
