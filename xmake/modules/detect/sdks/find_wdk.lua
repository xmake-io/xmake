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
-- @file        find_wdk.lua
--

-- imports
import("lib.detect.cache")
import("lib.detect.find_file")
import("core.base.option")
import("core.base.global")
import("core.project.config")
import("detect.sdks.find_vstudio")

-- find WDK directory
function _find_sdkdir(sdkdir)

    -- get sdk directory from the environment variables first
    if not sdkdir then
        sdkdir = os.getenv("WindowsSdkDir")
    end

    -- get sdk directory from vsvars
    if not sdkdir then
        local arch = config.arch() or os.arch()
        local vcvarsall = config.get("__vcvarsall")
        if not vcvarsall then
            local vstudio = find_vstudio()
            if vstudio then
                for _, vsinfo in pairs(vstudio) do
                    if vsinfo.vcvarsall then
                        vcvarsall = vsinfo.vcvarsall
                        break
                    end
                end
            end
        end
        if vcvarsall then
            sdkdir = (vcvarsall[arch] or {}).WindowsSdkDir
        end
    end
    return sdkdir
end

-- find umdf version
function _find_umdfver(libdir, includedir)

    -- find versions
    local versions = {}
    for _, p in ipairs(os.files(path.join(includedir, "wdf", "umdf", "*", "wdf.h"))) do
        table.insert(versions, path.filename(path.directory(p)))
    end

    -- find version
    local arch = config.arch() or os.arch()
    if arch then
        for _, ver in ipairs(versions) do
            if os.isfile(path.join(libdir, "wdf", "umdf", arch, ver, "WdfDriverStubUm.lib")) then
                return ver
            end
        end
    end
end

-- find kmdf version
function _find_kmdfver(libdir, includedir)

    -- find versions
    local versions = {}
    for _, p in ipairs(os.files(path.join(includedir, "wdf", "kmdf", "*", "wdf.h"))) do
        table.insert(versions, path.filename(path.directory(p)))
    end

    -- find version
    local arch = config.arch() or os.arch()
    if arch then
        for _, ver in ipairs(versions) do
            if os.isfile(path.join(libdir, "wdf", "kmdf", arch, ver, "wdfdriverentry.lib")) then
                return ver
            end
        end
    end
end

-- find WDK toolchains
function _find_wdk(sdkdir, sdkver)

    -- find wdk directory
    sdkdir = _find_sdkdir(sdkdir)
    if not sdkdir or not os.isdir(sdkdir) then
        return nil
    end

    -- get sdk version
    if not sdkver then
        local vers = {}
        for _, dir in ipairs(os.dirs(path.join(sdkdir, "Include", "*", "km"))) do
            table.insert(vers, path.filename(path.directory(dir)))
        end
        for _, ver in ipairs(vers) do
            if os.isdir(path.join(sdkdir, "Lib", ver, "km")) and os.isdir(path.join(sdkdir, "Lib", ver, "um")) and os.isdir(path.join(sdkdir, "Include", ver, "um"))  then
                sdkver = ver
                break
            end
        end
    end
    if not sdkver then
        return nil
    end

    -- get the bin directory
    local bindir = path.join(sdkdir, "bin")

    -- get the lib directory
    local libdir = path.join(sdkdir, "Lib")

    -- get the include directory
    local includedir = path.join(sdkdir, "Include")

    -- get umdf version
    local umdfver = _find_umdfver(libdir, includedir)

    -- get kmdf version
    local kmdfver = _find_kmdfver(libdir, includedir)

    -- get toolchains
    return {sdkdir = sdkdir, bindir = bindir, libdir = libdir, includedir = includedir, sdkver = sdkver, umdfver = umdfver, kmdfver = kmdfver}
end

-- find WDK toolchains
--
-- @param sdkdir    the WDK directory
-- @param opt       the argument options, e.g. {verbose = true, force = false, version = "5.9.1"}
--
-- @return          the WDK toolchains. e.g. {sdkver = ..., sdkdir = ..., bindir = .., libdir = ..., includedir = ..., .. }
--
-- @code
--
-- local toolchains = find_wdk("~/wdk")
--
-- @endcode
--
function main(sdkdir, opt)

    -- init arguments
    opt = opt or {}

    -- attempt to load cache first
    local key = "detect.sdks.find_wdk"
    local cacheinfo = cache.load(key)
    if not opt.force and cacheinfo.wdk and cacheinfo.wdk.sdkdir and os.isdir(cacheinfo.wdk.sdkdir) then
        return cacheinfo.wdk
    end

    -- find wdk
    local wdk = _find_wdk(sdkdir or config.get("wdk") or global.get("wdk") or config.get("sdk"), opt.version or config.get("wdk_sdkver"))
    if wdk then

        -- save to config
        config.set("wdk", wdk.sdkdir, {force = true, readonly = true})
        config.set("wdk_sdkver", wdk.sdkver, {force = true, readonly = true})

        -- trace
        if opt.verbose or option.get("verbose") then
            cprint("checking for WDK directory ... ${color.success}%s", wdk.sdkdir)
            cprint("checking for WDK version ... ${color.success}%s", wdk.sdkver)
        end
    else

        -- trace
        if opt.verbose or option.get("verbose") then
            cprint("checking for WDK directory ... ${color.nothing}${text.nothing}")
        end
    end

    -- save to cache
    cacheinfo.wdk = wdk or false
    cache.save(key, cacheinfo)

    -- ok?
    return wdk
end
