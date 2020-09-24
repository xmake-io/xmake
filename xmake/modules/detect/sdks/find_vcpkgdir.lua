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
-- @file        find_vcpkgdir.lua
--

-- imports
import("lib.detect.cache")
import("lib.detect.find_file")
import("core.base.option")
import("core.base.global")
import("core.project.config")

-- find vcpkg directory
function _find_vcpkgdir(sdkdir)

    -- init the search directories
    local paths = {}
    if sdkdir then
        table.insert(paths, sdkdir)
    end
    if is_host("windows") then
        -- attempt to read path info after running `vcpkg integrate install`
        local pathfile = "~/../Local/vcpkg/vcpkg.path.txt"
        if os.isfile(pathfile) then
            local dir = io.readfile(pathfile):trim()
            if os.isdir(dir) then
                table.insert(paths, dir)
            end
        end
    else
        -- TODO
    end

    -- attempt to find vcpkg
    local vcpkg = find_file(is_host("windows") and "vcpkg.exe" or "vcpkg", paths)
    if vcpkg then
        return path.directory(vcpkg)
    end
end

-- find vcpkg directory
--
-- @param sdkdir    the vcpkg directory
-- @param opt       the argument options, e.g. {verbose = true, force = false}
--
-- @return          the vcpkg directory
--
-- @code
--
-- local vcpkgdir = find_vcpkgdir()
--
-- @endcode
--
function main(sdkdir, opt)

    -- init arguments
    opt = opt or {}

    -- attempt to load cache first
    local key = "detect.sdks.find_vcpkgdir." .. (sdkdir or "")
    local cacheinfo = cache.load(key)
    if not opt.force and cacheinfo.vcpkg ~= nil then
        return cacheinfo.vcpkg
    end

    -- find vcpkg
    local vcpkg = _find_vcpkgdir(sdkdir or config.get("vcpkg") or global.get("vcpkg"))
    if vcpkg then

        -- save to config
        config.set("vcpkg", vcpkg, {force = true, readonly = true})

        -- trace
        if opt.verbose or option.get("verbose") then
            cprint("checking for vcpkg directory ... ${color.success}%s", vcpkg)
        end
    else

        -- trace
        if opt.verbose or option.get("verbose") then
            cprint("checking for vcpkg directory ... ${color.nothing}${text.nothing}")
        end
    end

    -- save to cache
    cacheinfo.vcpkg = vcpkg or false
    cache.save(key, cacheinfo)
    return vcpkg
end
