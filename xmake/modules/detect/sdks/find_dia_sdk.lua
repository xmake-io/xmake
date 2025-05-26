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
-- @author      redbeanw
-- @file        find_dia_sdk.lua
--

-- imports
import("core.project.config")
import("core.base.option")
import("core.tool.toolchain")
import("core.cache.detectcache")
import("detect.sdks.find_vstudio")

function _is_sdkdir_valid(sdkdir)
    return os.isfile(path.join(sdkdir, "lib", "diaguids.lib"))
end

function _find_sdkdir(sdkdir, opt)
    if not sdkdir then
        local vsdir = os.getenv("VSInstallDir")
        if not vsdir then
            if opt.toolchain then
                vcvars = opt.toolchain:config("vcvars")
                if vcvars then
                    vsdir = vcvars["VSInstallDir"]
                end
            end
        end
        if not vsdir then
            local msvc = toolchain.load("msvc", {plat = opt.plat or config.get("plat"), arch = opt.arch or config.get("arch")})
            if msvc and msvc:check() then
                local vcvars = msvc:config("vcvars")
                if vcvars then
                    vsdir = vcvars["VSInstallDir"]
                end
            end
        end
        if vsdir then
            sdkdir = path.join(vsdir, "DIA SDK")
        else
            return
        end
    end

    if not _is_sdkdir_valid(sdkdir) then
        sdkdir = path.join(sdkdir, "DIA SDK")
    end

    return _is_sdkdir_valid(sdkdir) and sdkdir or nil
end

function _find_dia_sdk(sdkdir, opt)
    -- get sdkdir
    sdkdir = _find_sdkdir(sdkdir, opt)
    if not sdkdir then
        return
    end

    -- get arch
    local arch = opt.arch or config.get("arch") or os.arch()
    if arch then
        local supported_arch = {
            x64 = "amd64",
            arm = "arm",
            arm64 = "arm64"
        }
        arch = supported_arch[arch]
    end
    if not arch then
        return
    end

    return {
        sdkdir = sdkdir,
        linkdirs = {
            path.join(sdkdir, "lib", arch),
            path.join(sdkdir, "bin", arch)
        },
        includedirs = {
            path.join(sdkdir, "include", arch)
        }
    }
end

-- find DIA SDK
--
-- @param sdkdir    the DIA SDK directory
-- @param opt       the argument options, e.g. {toolchain = ..., plat = ..., arch = ..., force = false, verbose = false}
--
-- @return          the DIA SDK. e.g. {sdkdir = ..., linkdirs = ..., includedirs = ...}
--
-- @code
--
-- local toolchains = find_dia_sdk("/opt/msvc/DIA SDK")
--
-- @endcode
--
function main(sdkdir, opt)
    opt = opt or {}

    -- attempt to load cache first
    local key = "detect.sdks.find_dia_sdk"
    local cacheinfo = detectcache:get(key) or {}
    if not opt.force and cacheinfo.dia_sdk and os.isdir(cacheinfo.dia_sdk.sdkdir) then
        return cacheinfo.dia_sdk
    end

    -- find dia sdk
    local dia_sdk = _find_dia_sdk(sdkdir, opt)
    if not dia_sdk then
        local vstudio = find_vstudio()
        if vstudio then
            for vsver, value in pairs(vstudio) do
                if value.vcvarsall then
                    for arch, vcvarsall_value in pairs(value.vcvarsall) do
                        local VSInstallDir = vcvarsall_value.VSInstallDir
                        if VSInstallDir then
                            dia_sdk = _find_dia_sdk(VSInstallDir, opt)
                            if dia_sdk then
                                goto found
                            end
                        end
                    end
                end
            end
        end
    end

::found::

    if dia_sdk then
        if opt.verbose or option.get("verbose") then
            cprint("checking for DIA SDK directory ... ${color.success}%s", dia_sdk.sdkdir)
        end
    else
        if opt.verbose or option.get("verbose") then
            cprint("checking for DIA SDK directory ... ${color.nothing}${text.nothing}")
        end
    end

    -- save to cache
    cacheinfo.dia_sdk = dia_sdk or false
    detectcache:set(key, cacheinfo)
    detectcache:save()
    return dia_sdk
end
