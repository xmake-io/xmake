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
-- @file        find_mingw.lua
--

-- imports
import("lib.detect.cache")
import("core.base.option")
import("core.base.global")
import("core.project.config")
import("detect.sdks.find_cross_toolchain")

-- find mingw directory
function _find_mingwdir(sdkdir)

    -- get mingw directory
    if not sdkdir then
        if is_host("macosx") then
            sdkdir = "/usr/local/opt/mingw-w64"
        end
    end

    -- get mingw directory
    if sdkdir and os.isdir(sdkdir) then
        return sdkdir
    end
end

-- find the mingw toolchain
function _find_mingw(sdkdir, bindir, cross)

    -- find mingw root directory
    sdkdir = _find_mingwdir(sdkdir)
    if not sdkdir then
        return {}
    end

    -- select cross on macos, e.g x86_64-w64-mingw32- or i686-w64-mingw32-
    if is_host("macosx") and not cross then
        local arch = config.get("arch")
        if not arch or arch == "i386" then
            cross = "i686-*-"
        else
            cross = "x86_64-*-"
        end
    end

    -- find cross toolchain
    local toolchain = find_cross_toolchain(sdkdir or bindir, {bindir = bindir, cross = cross})
    if toolchain then
        return {sdkdir = toolchain.sdkdir, bindir = toolchain.bindir, cross = toolchain.cross}
    end
end

-- find mingw toolchains
--
-- @param sdkdir    the mingw directory
-- @param opt       the argument options 
--                  e.g. {verbose = true, force = false, bindir = .., cross = ...}  
--
-- @return          the mingw toolchains. e.g. {sdkdir = .., bindir = .., cross = ..}
--
-- @code 
--
-- local toolchain = find_mingw("/xxx/android-mingw-r10e")
-- local toolchain = find_mingw("/xxx/android-mingw-r10e", {force = true, verbose = true})
-- 
-- @endcode
--
function main(sdkdir, opt)

    -- init arguments
    opt = opt or {}

    -- attempt to load cache first
    local key = "detect.sdks.find_mingw"
    local cacheinfo = cache.load(key)
    if not opt.force and cacheinfo.mingw and cacheinfo.mingw.sdkdir and os.isdir(cacheinfo.mingw.sdkdir) then
        return cacheinfo.mingw
    end

    -- find mingw
    local mingw = _find_mingw(sdkdir or config.get("mingw") or global.get("mingw") or config.get("sdk"), opt.bindir or config.get("bin"), opt.cross or config.get("cross"))
    if mingw and mingw.sdkdir then

        -- save to config
        config.set("mingw", mingw.sdkdir, {force = true, readonly = true})

        -- trace
        if opt.verbose or option.get("verbose") then
            cprint("checking for the mingw directory ... ${color.success}%s", mingw.sdkdir)
        end
    else

        -- trace
        if opt.verbose or option.get("verbose") then
            cprint("checking for the mingw directory ... ${color.nothing}${text.nothing}")
        end
    end

    -- save to cache
    cacheinfo.mingw = mingw or false
    cache.save(key, cacheinfo)

    -- ok?
    return mingw
end
