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
-- Copyright (C) 2015-present, Xmake Open Source Community.
--
-- @author      ruki
-- @file        find_mingw.lua
--

-- imports
import("lib.detect.find_path")
import("core.base.option")
import("core.base.global")
import("core.project.config")
import("core.cache.detectcache")
import("detect.sdks.find_cross_toolchain")

-- find mingw directory
function _find_mingwdir(sdkdir, msystem)
    if not sdkdir then
        if is_host("macosx", "linux") and os.isdir("/opt/llvm-mingw") then
            sdkdir = "/opt/llvm-mingw"
        elseif is_host("macosx") and os.isdir("/usr/local/opt/mingw-w64") then
            -- for macOS Intel
            sdkdir = "/usr/local/opt/mingw-w64"
        elseif is_host("macosx") and os.isdir("/opt/homebrew/opt/mingw-w64") then
            -- for Apple Silicon
            sdkdir = "/opt/homebrew/opt/mingw-w64"
        elseif is_host("linux") then
            sdkdir = "/usr"
        else
            local mingw_prefix = is_subhost("msys") and os.getenv("MINGW_PREFIX") or os.getenv("LLVM_MINGW_DIR") or os.getenv("LLVM_MINGW_ROOT")
            if mingw_prefix and os.isdir(mingw_prefix) then
                sdkdir = mingw_prefix
            end
        end
        -- attempt to get it from $PATH
        -- @see https://github.com/xmake-io/xmake/issues/977
        if not sdkdir then
            local pathenv = os.getenv("PATH")
            if pathenv then
                local buildhash_pattern = string.rep('%x', 32)
                local match_pattern = "[\\/]packages[\\/]%w[\\/].*mingw.*[\\/][^\\/]+[\\/]" .. buildhash_pattern .. "[\\/]bin"
                for _, p in ipairs(path.splitenv(pathenv)) do
                    if (p:find(match_pattern) or p:find(string.ipattern("mingw[%w%-%_%+]*[\\/]bin"))) and
                        path.filename(p) == "bin" and os.isdir(p) then
                        sdkdir = path.directory(p)
                        break
                    end
                end
            end
        end
    end

    if is_subhost("msys") and sdkdir and msystem and not sdkdir:find(msystem, 1, true) then
        sdkdir = path.unix(path.join(path.directory(sdkdir), msystem))
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
function _find_mingw(sdkdir, opt)
    opt = opt or {}
    local bindir = opt.bindir
    local cross = opt.cross
    local msystem = opt.msystem
    local arch = opt.arch or config.get("arch") or os.arch()

    -- find mingw root directory
    sdkdir = _find_mingwdir(sdkdir, msystem)
    if not sdkdir then
        return
    end

    -- select cross on macOS, e.g x86_64-w64-mingw32- or i686-w64-mingw32-
    if not cross then
        if arch == "i386" or arch == "x86" or arch == "i686" then
            cross = "i686-w64-mingw32-"
        elseif arch == "arm64" or arch == "aarch64" then
            cross = "aarch64-w64-mingw32-" -- for llvm-mingw
        elseif arch:startswith("arm") then
            cross = "armv7-w64-mingw32-"   -- for llvm-mingw
        else
            cross = "x86_64-w64-mingw32-"
        end
    end

    -- find cross toolchain
    local toolchain = find_cross_toolchain(sdkdir or bindir, {bindir = bindir, cross = cross})
    if not toolchain then -- fallback, e.g. gcc.exe without cross
        toolchain = find_cross_toolchain(sdkdir or bindir, {bindir = bindir})
    end
    if toolchain then
        return {sdkdir = toolchain.sdkdir, bindir = toolchain.bindir, cross = toolchain.cross, msystem = msystem}
    end
end

-- find mingw toolchains
--
-- @param sdkdir    the mingw directory
-- @param opt       the argument options
--                  e.g. {verbose = true, force = false, bindir = .., cross = ..., arch = ...}
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
    opt = opt or {}

    -- attempt to load cache first
    local key = "detect.sdks.find_mingw"
    local cacheinfo = detectcache:get(key) or {}
    if not opt.force and cacheinfo.mingw and cacheinfo.mingw.sdkdir and os.isdir(cacheinfo.mingw.sdkdir)
        and cacheinfo.mingw.msystem == opt.msystem then
        return cacheinfo.mingw
    end

    -- find mingw
    local mingw = _find_mingw(sdkdir or config.get("mingw") or global.get("mingw") or config.get("sdk"), {
        bindir = opt.bindir or config.get("bin"),
        cross = opt.cross or config.get("cross"),
        msystem = opt.msystem,
        arch = opt.arch
    })
    if mingw and mingw.sdkdir then
        config.set("mingw", mingw.sdkdir, {force = true, readonly = true})
        if opt.verbose or option.get("verbose") then
            cprint("checking for Mingw SDK ... ${color.success}%s (%s)", mingw.sdkdir, mingw.cross)
        end
    else
        if opt.verbose or option.get("verbose") then
            cprint("checking for Mingw SDK ... ${color.nothing}${text.nothing}")
        end
    end

    -- save to cache
    cacheinfo.mingw = mingw or false
    detectcache:set(key, cacheinfo)
    return mingw
end
