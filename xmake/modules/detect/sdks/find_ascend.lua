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
-- @author      wuzhenqing
-- @file        find_ascend.lua
--

-- imports
import("core.base.option")
import("core.base.global")
import("core.project.config")
import("core.cache.detectcache")

-- map host arch to CANN host tool subdirectory
function _host_archdir(arch)
    local host_archdirs = {
        x86_64  = "x86_64-linux"
    ,   x64     = "x86_64-linux"
    ,   arm64   = "aarch64-linux"
    ,   aarch64 = "aarch64-linux"
    }
    return host_archdirs[arch]
end

-- find ascend sdk root directory
function _find_sdkdir(sdkdir)
    if not sdkdir then
        sdkdir = os.getenv("ASCEND_HOME_PATH") or os.getenv("ASCEND_TOOLKIT_HOME")
    end
    if sdkdir and os.isdir(sdkdir) then
        return path.absolute(sdkdir)
    end
end

-- find ascend sdk
function _find_ascend(sdkdir)
    sdkdir = _find_sdkdir(sdkdir)
    if not sdkdir then
        return
    end

    local archdir = _host_archdir(os.arch())
    if not archdir then
        return
    end

    local hostroot = path.join(sdkdir, archdir)
    if not os.isdir(hostroot) then
        return
    end

    local bindir = path.join(hostroot, "bin")
    local libdir = path.join(hostroot, "lib64")
    if not os.isexec(path.join(bindir, "bisheng")) then
        return
    end

    return {sdkdir       = sdkdir,
            hostroot     = hostroot,
            bindir       = bindir,
            libdir       = libdir,
            host_archdir = archdir}
end

-- find Ascend SDK
--
-- @param sdkdir    the Ascend SDK directory (optional, e.g. /usr/local/Ascend/ascend-toolkit/latest)
-- @param opt       the argument options, e.g. {verbose = true, force = false}
--
-- @return          the Ascend SDK info, e.g. {sdkdir, hostroot, bindir, libdir, host_archdir}
--
-- @code
--
-- local ascend = find_ascend()
-- local ascend = find_ascend("/usr/local/Ascend/ascend-toolkit/latest")
--
-- @endcode
--
function main(sdkdir, opt)

    -- init arguments
    opt = opt or {}

    -- attempt to load cache first
    local key = "detect.sdks.find_ascend"
    local cacheinfo = detectcache:get(key) or {}
    if not opt.force and cacheinfo.ascend and cacheinfo.ascend.sdkdir and os.isdir(cacheinfo.ascend.sdkdir) then
        return cacheinfo.ascend
    end

    -- find ascend
    local ascend = _find_ascend(sdkdir or config.get("ascend") or global.get("ascend") or config.get("sdk"))
    if ascend then

        -- save to config
        config.set("ascend", ascend.sdkdir, {force = true, readonly = true})

        -- trace
        if opt.verbose or option.get("verbose") then
            cprint("checking for Ascend SDK directory ... ${color.success}%s", ascend.sdkdir)
        end
    else

        -- trace
        if opt.verbose or option.get("verbose") then
            cprint("checking for Ascend SDK directory ... ${color.nothing}${text.nothing}")
        end
    end

    -- save to cache
    cacheinfo.ascend = ascend or false
    detectcache:set(key, cacheinfo)
    return ascend
end
