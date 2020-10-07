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
-- @file        find_mingw.lua
--

-- imports
import("lib.detect.cache")
import("lib.detect.find_path")
import("core.base.option")
import("core.base.global")
import("core.project.config")
import("detect.sdks.find_cross_toolchain")

-- find mingw directory
function _find_mingwdir(sdkdir)

    -- get mingw directory
    if not sdkdir then
        if is_host("macosx", "linux") and os.isdir("/opt/llvm-mingw") then
            sdkdir = "/opt/llvm-mingw"
        elseif is_host("macosx") and os.isdir("/usr/local/opt/mingw-w64") then
            sdkdir = "/usr/local/opt/mingw-w64"
        elseif is_host("linux") then
            sdkdir = "/usr"
        elseif is_subhost("msys") then
            local mingw_prefix = os.getenv("MINGW_PREFIX")
            if mingw_prefix and os.isdir(mingw_prefix) then
                sdkdir = mingw_prefix
            end
        end
        -- attempt to get it from $PATH
        -- @see https://github.com/xmake-io/xmake/issues/977
        if not sdkdir then
            local pathenv = os.getenv("PATH")
            if pathenv then
                for _, p in ipairs(path.splitenv(pathenv)) do
                    if p:find(string.ipattern("mingw[%w%-%_%+]*[\\/]bin")) and path.filename(p) == "bin" and os.isdir(p) then
                        sdkdir = path.directory(p)
                        break
                    end
                end
            end
        end
    end

    -- attempt to find mingw directory from the qt sdk
    local qt = config.get("qt")
    if not sdkdir and qt then
        sdkdir = find_path("bin", path.join(qt, "Tools", "mingw*_" .. (is_arch("x86_64") and "64" or "32")))
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
        return
    end

    -- select cross on macOS, e.g x86_64-w64-mingw32- or i686-w64-mingw32-
    if not cross then
        if is_arch("i386", "x86", "i686") then
            cross = "i686-*-"
        elseif is_arch("arm64", "aarch64") then
            cross = "aarch64-*-" -- for llvm-mingw
        elseif is_arch("arm.*") then
            cross = "armv7-*-"   -- for llvm-mingw
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
            cprint("checking for mingw directory ... ${color.success}%s", mingw.sdkdir)
        end
    else

        -- trace
        if opt.verbose or option.get("verbose") then
            cprint("checking for mingw directory ... ${color.nothing}${text.nothing}")
        end
    end

    -- save to cache
    cacheinfo.mingw = mingw or false
    cache.save(key, cacheinfo)

    -- ok?
    return mingw
end
