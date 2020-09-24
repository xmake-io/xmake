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
-- @file        find_dotnet.lua
--

-- imports
import("lib.detect.cache")
import("lib.detect.find_file")
import("core.base.option")
import("core.base.global")
import("core.project.config")

-- find dotnet directory
function _find_sdkdir(sdkdir)

    -- get sdk directory from vsvars
    if not sdkdir then
        local arch = config.arch()
        local vcvarsall = config.get("__vcvarsall")
        if vcvarsall then
            sdkdir = (vcvarsall[arch] or {}).WindowsSdkDir
            if sdkdir then
                sdkdir = path.join(path.directory(path.translate(sdkdir)), "NETFXSDK")
            end
        end
    end
    return sdkdir
end

-- find dotnet toolchains
function _find_dotnet(sdkdir, sdkver)

    -- find dotnet directory
    sdkdir = _find_sdkdir(sdkdir)
    if not sdkdir or not os.isdir(sdkdir) then
        return nil
    end

    -- get sdk version
    if not sdkver then
        local vers = {}
        for _, dir in ipairs(os.dirs(path.join(sdkdir, "*", "Include"))) do
            table.insert(vers, path.filename(path.directory(dir)))
        end
        for _, ver in ipairs(vers) do
            if os.isdir(path.join(sdkdir, ver, "Lib", "um")) and os.isdir(path.join(sdkdir, ver, "Include", "um"))  then
                sdkver = ver
                break
            end
        end
    end
    if not sdkver then
        return nil
    end

    -- get the lib directory
    local libdir = path.join(sdkdir, sdkver, "Lib")

    -- get the include directory
    local includedir = path.join(sdkdir, sdkver, "Include")

    -- get toolchains
    return {sdkdir = sdkdir, libdir = libdir, includedir = includedir, sdkver = sdkver}
end

-- find dotnet toolchains
--
-- @param sdkdir    the dotnet directory
-- @param opt       the argument options, e.g. {verbose = true, force = false, version = "5.9.1"}
--
-- @return          the dotnet toolchains. e.g. {sdkver = ..., sdkdir = ..., bindir = .., libdir = ..., includedir = ..., .. }
--
-- @code
--
-- local toolchains = find_dotnet("~/dotnet")
--
-- @endcode
--
function main(sdkdir, opt)

    -- init arguments
    opt = opt or {}

    -- attempt to load cache first
    local key = "detect.sdks.find_dotnet." .. (sdkdir or "")
    local cacheinfo = cache.load(key)
    if not opt.force and cacheinfo.dotnet then
        return cacheinfo.dotnet
    end

    -- find dotnet
    local dotnet = _find_dotnet(sdkdir or config.get("dotnet") or global.get("dotnet"), opt.version or config.get("dotnet_sdkver"))
    if dotnet then

        -- save to config
        config.set("dotnet", dotnet.sdkdir, {force = true, readonly = true})
        config.set("dotnet_sdkver", dotnet.sdkver, {force = true, readonly = true})

        -- trace
        if opt.verbose or option.get("verbose") then
            cprint("checking for .Net SDK directory ... ${color.success}%s", dotnet.sdkdir)
            cprint("checking for .Net SDK version ... ${color.success}%s", dotnet.sdkver)
        end
    else

        -- trace
        if opt.verbose or option.get("verbose") then
            cprint("checking for .Net SDK directory ... ${color.nothing}${text.nothing}")
        end
    end

    -- save to cache
    cacheinfo.dotnet = dotnet or false
    cache.save(key, cacheinfo)

    -- ok?
    return dotnet
end
