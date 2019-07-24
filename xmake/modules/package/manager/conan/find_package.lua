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
-- @file        find_package.lua
--

-- imports
import("core.base.option")
import("core.project.config")

-- get build info file
function _conan_get_buildinfo_file(name)
    return path.absolute(path.join(config.buildir() or os.tmpdir(), ".conan", name, "conanbuildinfo.xmake.lua"))
end

-- get conan platform 
function _conan_get_plat(opt)
    local plats = {macosx = "Macos", windows = "Windows", linux = "Linux"}
    return plats[opt.plat]
end

-- get conan architecture 
function _conan_get_arch(opt)
    if opt.plat == "windows" then
        return opt.arch == "x64" and "x86_64" or "x86"
    else
        return opt.arch == "i386" and "x86" or opt.arch
    end
end

-- get conan mode
function _conan_get_mode(opt)
    return opt.mode == "debug" and "Debug" or "Release"
end

-- find package using the conan package manager
--
-- @param name  the package name
-- @param opt   the options, e.g. {verbose = true, version = "1.12.x")
--
function main(name, opt)

    -- get the build info
    local buildinfo_file = _conan_get_buildinfo_file(name)
    if not os.isfile(buildinfo_file) then
        return 
    end

    -- load build info
    local buildinfo = io.load(buildinfo_file)

    -- get platform, architecture and mode
    local plat = _conan_get_plat(opt)
    local arch = _conan_get_arch(opt)
    local mode = _conan_get_mode(opt)
    if not plat and not arch and not mode then
        return 
    end

    -- get the package info of the given platform, architecture and mode
    local found = false
    local result = {}
    for k, v in pairs(buildinfo[plat .. "_" .. arch .. "_" .. mode]) do
        if #table.wrap(v) > 0 then
            result[k] = v
            found = true
        end
    end
    if found then
        for _, linkdir in ipairs(result.linkdirs) do
            if not os.isdir(linkdir) then
                return 
            end
        end
        for _, includedir in ipairs(result.includedirs) do
            if not os.isdir(includedir) then
                return 
            end
        end
        return result
    end
end
