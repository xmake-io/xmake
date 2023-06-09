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
-- @author      ruki, Lingfeng Fu
-- @file        search_package.lua
--

-- imports
import("core.base.option")
import("lib.detect.find_tool")

-- search package using the zypper package manager
--
-- @param name  the package name with pattern
--
function main(name)

    -- find zypper
    local zypper = find_tool("zypper")
    if not zypper then
        raise("zypper not found!")
    end

    -- search packages
    --
    --    | libboost_wave-devel     | Development headers for Boost.Wave library  | package
    --
    -- i  | libboost_wave-devel     | Development headers for Boost.Wave library  | package
    --
    -- i+ | libboost_headers-devel  | Development headers for Boost               | package
    --
    local results = {}
    local searchdata = os.iorunv(zypper.program, { "search", name })
    for _, line in ipairs(searchdata:split("\n", { plain = true })) do
        if line:endswith("package") then
            local splitinfo = line:split("%s+|%s+", { limit = 4 })
            if not line:startswith(" ") then
                table.remove(splitinfo, 1)
            end
            local packagename = splitinfo[1]
            local description = splitinfo[2]
            table.insert(results, { name = "zypper::" .. packagename, version = version, description = description })
        end
    end
    return results
end
