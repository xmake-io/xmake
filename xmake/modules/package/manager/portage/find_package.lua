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
import("lib.detect.find_file")
import("lib.detect.find_tool")
import("package.manager.pkgconfig.find_package", {alias = "find_package_from_pkgconfig"})

-- find package from the system directories
--
-- @param name  the package name
-- @param opt   the options, e.g. {verbose = true, version = "1.12.x")
--
function main(name, opt)

    -- init options
    opt = opt or {}

    -- for msys2/mingw? mingw-w64-[i686|x86_64]-xxx
    if opt.plat == "mingw" then
        name = "mingw64-runtime" -- there is only one package for mingw
    end

    -- get package contents file
    local file = find_file("CONTENTS", "/var/db/pkg/*/" .. name .. "-*")
    if not file then
        return
    end

    -- get package files list
    local list = {}
    local file_contents = io.readfile(file)
    for _, entry in pairs(file_contents:split("\n")) do
        -- the file path is the second element after being delimited by spaces
        local split_entry = entry:split(" ")[2]
        if split_entry then
            table.insert(list, split_entry)
        end
    end

    -- parse package files list
    local linkdirs = {}
    local has_includes = false
    local pkgconfig_files = {}
    for _, line in ipairs(list) do
        line = line:trim():split('%s+')[1]
        if line:find("/pkgconfig/", 1, true) and line:endswith(".pc") then
            pkgconfig_files[path.basename(line)] = line
        end
        if line:endswith(".so") or line:endswith(".a") or line:endswith(".lib") then
            table.insert(linkdirs, path.directory(line))
        elseif line:find("/include/", 1, true) and (line:endswith(".h") or line:endswith(".hpp")) then
            has_includes = true
        end
    end

    -- get pkgconfig file
    local pkgconfig_file = pkgconfig_files[name]
    if not pkgconfig_file then
        for _, file in pairs(pkgconfig_files) do
            pkgconfig_file = file
            break
        end
    end

    -- find package
    local result = nil
    if pkgconfig_file then
        local pkgconfig_dir = path.directory(pkgconfig_file)
        local pkgconfig_name = path.basename(pkgconfig_file)
        linkdirs = table.unique(linkdirs)
        includedirs = table.unique(includedirs)
        result = find_package_from_pkgconfig(pkgconfig_name, {configdirs = pkgconfig_dir, linkdirs = linkdirs})
        if not result and has_includes then
            -- header only and hidden /usr/include? we need only return empty {}
            result = {}
        end
    end
    return result
end
