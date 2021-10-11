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
    -- e.g. OpenCV 4.1.1, Boost COMPONENTS regex system
    local requirestr = name
    if opt.required_version then
        requirestr = requirestr .. " " .. opt.required_version
    end
    cmakefile:print("project(find_package)")
    cmakefile:print("find_package(%s REQUIRED)", requirestr)
    cmakefile:print("if(%s_FOUND)", name)
    for _, macroname in ipairs({name, name:upper()}) do
        cmakefile:print("   message(STATUS \"%s_INCLUDE_DIR=\" \"${%s_INCLUDE_DIR}\")", macroname, macroname)
        cmakefile:print("   message(STATUS \"%s_INCLUDE_DIRS=\" \"${%s_INCLUDE_DIRS}\")", macroname, macroname)
        cmakefile:print("   message(STATUS \"%s_LIBRARY=\" \"${%s_LIBRARY}\")", macroname, macroname)
        cmakefile:print("   message(STATUS \"%s_LIBS=\" \"${%s_LIBS}\")", macroname, macroname)
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
            for _, macroname in ipairs({name, name:upper()}) do
                -- parse includedirs
                for _, includedir_key in ipairs({macroname .. "_INCLUDE_DIR=", macroname .. "_INCLUDE_DIRS="}) do
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

                -- parse links and linkdirs
                for _, library_key in ipairs({macroname .. "_LIBRARY=", macroname .. "_LIBS="}) do
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
    if true then --links or includedirs then
        local results = {}
        results.links = table.reverse_unique(links)
        results.linkdirs = table.unique(linkdirs)
        results.includedirs = table.unique(includedirs)
        return results
    end
end

-- find package using the cmake package manager
--
-- @param name  the package name
-- @param opt   the options, e.g. {verbose = true, required_version = "1.0")
--
function main(name, opt)
    opt = opt or {}
    local cmake = find_tool("cmake", {version = true})
    if not cmake then
        return
    end
    return _find_package(cmake, name, opt)
end
