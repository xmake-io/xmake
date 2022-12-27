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
-- @author      ruki
-- @file        find_package.lua
--

-- imports
import("core.base.option")
import("core.base.semver")
import("core.base.hashset")
import("core.project.config")
import("core.project.target")
import("lib.detect.find_tool")
import("lib.detect.find_file")

-- get rust library name
--
-- e.g.
-- sdl2 -> libsdl2
-- obj-rs -> libobj
function _get_libname(name)
    return "lib" .. name:split("%-")[1]
end

-- get the name set of libraries
function _get_names_of_libraries(name, configs)
    local names = hashset.new()
    if configs.cargo_toml then
        local dependencies = false
        local cargo_file = io.open(configs.cargo_toml)
        for line in cargo_file:lines() do
            line = line:trim()
            if not dependencies and line == "[dependencies]" then
                dependencies = true
            elseif dependencies then
                if not line:startswith("[") then
                    local splitinfo = line:split("=", {plain = true})
                    if splitinfo and #splitinfo > 1 then
                        name = splitinfo[1]:trim()
                        if #name > 0 then
                            names:insert(_get_libname(name))
                        end
                    end
                else
                    break
                end
            end
        end
        cargo_file:close()
    else
        names:insert(_get_libname(name))
    end
    return names
end

-- find package using the cargo package manager
--
-- @param name  the package name
-- @param opt   the options, e.g. {verbose = true, require_version = "1.12.x")
--
function main(name, opt)

    -- get configs
    opt = opt or {}
    local configs = opt.configs or {}

    -- get names of libraries
    local names = _get_names_of_libraries(name, configs)
    assert(not names:empty())

    local frameworkdirs
    local frameworks
    local librarydir = path.join(opt.installdir, "lib")
    local libfiles = os.files(path.join(librarydir, "*.rlib"))
    for _, libraryfile in ipairs(libfiles) do
        local filename = path.filename(libraryfile)
        local libraryname = filename:split('-', {plain = true})[1]
        if names:has(libraryname) then
            frameworkdirs = frameworkdirs or {}
            frameworks = frameworks or {}
            table.insert(frameworkdirs, librarydir)
            table.insert(frameworks, libraryfile)
        end
    end
    local result
    if frameworks and frameworkdirs then
        result = result or {}
        result.libfiles = libfiles
        result.frameworkdirs = frameworkdirs and table.unique(frameworkdirs) or nil
        result.frameworks = frameworks
        result.version = opt.require_version
    end
    return result
end
