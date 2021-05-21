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

-- search package using the conda package manager
--
-- @param name  the package name with pattern
--
function main(name)

    -- find conda
    local conda = find_tool("conda")
    if not conda then
        raise("conda not found!")
    end

    -- search packages
    local results = {}
    local searchdata = os.iorunv(conda.program, {"search", "-q", name})
    for _, line in ipairs(searchdata:split("\n", {plain = true})) do
        local splitinfo = line:split("%s+", {limit = 3})
        local packagename = splitinfo[1]
        local version = splitinfo[2]
        local description = splitinfo[3]
        if packagename:find(name, 1, true) then
            table.insert(results, {name = "conda::" .. packagename, version = version, description = description})
        end
    end
    return results
end
