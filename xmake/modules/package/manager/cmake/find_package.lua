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
import("core.project.target")
import("lib.detect.find_tool")

-- find package
function _find_package(cmake, name, opt)

    -- get work directory
    local workdir = os.tmpfile() .. ".dir"
    os.tryrm(workdir)
    os.mkdir(workdir)

    -- generate CMakeLists.txt
    local cmakefile = io.open(path.join(workdir, "CMakeLists.txt"), "w")
    if cmake.version then
        cmakefile:print("cmake_minimum_required(VERSION %s)", cmake.version)
    end
    cmakefile:print("project(find_package)")

    -- e.g. OpenCV 4.1.1, Boost COMPONENTS regex system
    local requirestr = name
    if opt.required_version then
        requirestr = requirestr .. " " .. opt.required_version
    end
    if opt.components then
        requirestr = requirestr .. " COMPONENTS"
        for _, component in ipairs(opt.components) do
            requirestr = requirestr .. " " .. component
        end
    end
    if opt.moduledirs then
        for _, moduledir in ipairs(opt.moduledirs) do
            cmakefile:print("add_cmake_modules(%s)", moduledir)
        end
    end
    cmakefile:print("find_package(%s REQUIRED)", requirestr)
    cmakefile:print("if(%s_FOUND)", name)
    for _, macro_name in ipairs({name, name:upper()}) do
        cmakefile:print("   message(STATUS \"%s_INCLUDE_DIR=\" \"${%s_INCLUDE_DIR}\")", macro_name, macro_name)
        cmakefile:print("   message(STATUS \"%s_INCLUDE_DIRS=\" \"${%s_INCLUDE_DIRS}\")", macro_name, macro_name)
        cmakefile:print("   message(STATUS \"%s_LIBRARY_DIR=\" \"${%s_LIBRARY_DIR}\")", macro_name, macro_name)
        cmakefile:print("   message(STATUS \"%s_LIBRARY_DIRS=\" \"${%s_LIBRARY_DIRS}\")", macro_name, macro_name)
        cmakefile:print("   message(STATUS \"%s_LIBRARY=\" \"${%s_LIBRARY}\")", macro_name, macro_name)
        cmakefile:print("   message(STATUS \"%s_LIBRARIES=\" \"${%s_LIBRARIES}\")", macro_name, macro_name)
        cmakefile:print("   message(STATUS \"%s_LIBS=\" \"${%s_LIBS}\")", macro_name, macro_name)
        --[[
        for _, component in ipairs(opt.components) do
            local component_name = component:upper()
            cmakefile:print("   message(STATUS \"%s_%s_LIBRARY_RELEASE=\" \"${%s_%s_LIBRARY_RELEASE}\")",
                macro_name, component_name, macro_name, component_name)
        end]]
    end
    cmakefile:print("endif(%s_FOUND)", name)
    cmakefile:close()

    -- run cmake to get output
    local links
    local linkdirs
    local includedirs
    local output, errors = try {function() return os.iorunv(cmake.program, {workdir}, {curdir = workdir}) end}
    if output then
        for _, line in ipairs(output:split("\n", {plain = true})) do
            for _, macro_name in ipairs({name, name:upper()}) do
                -- parse includedirs
                for _, includedir_key in ipairs({macro_name .. "_INCLUDE_DIR=", macro_name .. "_INCLUDE_DIRS="}) do
                    if line:find(includedir_key, 1, true) then
                        local splitinfo = line:split(includedir_key)
                        local values = splitinfo[2]
                        if values then
                            values = values:split(';', {plain = true})
                        end
                        if values then
                            includedirs = includedirs or {}
                            table.join2(includedirs, values)
                        end
                    end
                end

                -- parse linkdirs
                for _, linkdir_key in ipairs({macro_name .. "_LIBRARY_DIR=", macro_name .. "_LIBRARY_DIRS="}) do
                    if line:find(linkdir_key, 1, true) then
                        local splitinfo = line:split(linkdir_key)
                        local values = splitinfo[2]
                        if values then
                            values = values:split(';', {plain = true})
                        end
                        if values then
                            linkdirs = linkdirs or {}
                            table.join2(linkdirs, values)
                        end
                    end
                end

                -- parse links and linkdirs
                for _, library_key in ipairs({macro_name .. "_LIBRARY=", macro_name .. "_LIBS=", macro_name .. "_LIBRARIES="}) do
                    if line:find(library_key, 1, true) then
                        local splitinfo = line:split(library_key)
                        local values = splitinfo[2]
                        if values then
                            values = values:split(';', {plain = true})
                        end
                        for _, library in ipairs(values) do
                            local linkdir = path.directory(library)
                            if linkdir ~= "." then
                                linkdirs = linkdirs or {}
                                table.insert(linkdirs, linkdir)
                            end
                            local link = target.linkname(path.filename(library))
                            if not link then
                                -- has been link name?
                                if path.filename(library) == path.basename(library) and linkdir == "." then
                                    link = library
                                end
                            end
                            if link then
                                assert(not link:find("::", 1, true), "link(%s) is not supported yet!", link)
                                links = links or {}
                                table.insert(links, link)
                            end
                        end
                    end
                end
            end
        end
    end

    -- trace diagnosis info
    if option.get("verbose") then
        if output then
            print(output)
        end
        if option.get("diagnosis") and errors and errors:trim() ~= "" then
            cprint("${color.warning}checkinfo: ${clear dim}" .. errors)
        end
    end

    -- remove work directory
    os.tryrm(workdir)

    -- get results
    if links or includedirs then
        local results = {}
        results.links = table.reverse_unique(links)
        results.linkdirs = table.unique(linkdirs)
        results.includedirs = table.unique(includedirs)
        return results
    end
end

-- find package using the cmake package manager
--
-- e.g.
--
-- find_package("cmake::ZLIB")
-- find_package("cmake::OpenCV", {required_version = "4.1.1"})
-- find_package("cmake::Boost", {components = {"regex", "system"}})
-- find_package("cmake::Foo", {moduledirs = "xxx"})
--
-- @param name  the package name
-- @param opt   the options, e.g. {verbose = true, required_version = "1.0",
--                                 components = {"regex", "system"},
--                                 moduledirs = "xxx")
--
function main(name, opt)
    opt = opt or {}
    local cmake = find_tool("cmake", {version = true})
    if not cmake then
        return
    end
    return _find_package(cmake, name, opt)
end
