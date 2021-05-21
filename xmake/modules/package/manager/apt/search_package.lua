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
-- @file        search_package.lua
--

-- imports
import("core.base.option")
import("lib.detect.find_tool")

-- search package using the apt package manager
--
-- @param name  the package name with pattern
--
function main(name)

    -- find apt
    local apt = find_tool("apt")
    if not apt then
        raise("apt not found!")
    end

    -- search packages
    --
    -- libzopfli1/groovy 1.0.3-1build1 amd64
    --  zlib (gzip, deflate) compatible compressor - shared library
    --
    -- lua-zlib/groovy 1.2-2 amd64
    --  zlib library for the Lua language
    --
    local results = {}
    local searchdata = os.iorunv(apt.program, {"search", name})
    local packagename
    for _, line in ipairs(searchdata:split("\n", {plain = true})) do
        if line:find("/", 1, true) then
            local splitinfo = line:split("%s+", {limit = 3})
            packagename = splitinfo[1]
            if packagename then
                packagename = packagename:split('/')[1]
            end
        elseif line:trim() ~= "" and packagename then
            local description = line:trim()
            if packagename:find(name, 1, true) then
                table.insert(results, {name = "apt::" .. packagename, version = version, description = description})
            end
            packagename = nil
        end
    end
    return results
end
