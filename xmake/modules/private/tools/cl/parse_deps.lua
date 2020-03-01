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
-- @file        parse_deps.lua
--

-- imports
import("core.project.project")
import("core.base.hashset")
import("parse_include")

-- parse depsfiles from string
function main(depsdata)

    -- translate it
    local results = hashset.new()
    for _, line in ipairs(depsdata:split("\n", {plain = true})) do

        -- get includefile
        local includefile = parse_include(line:trim())
        if includefile then

            -- get the relative
            includefile = path.relative(includefile, project.directory())
            includefile = path.absolute(includefile)

            -- save it if belong to the project
            if includefile:startswith(os.projectdir()) then

                -- insert it and filter repeat
                includefile = path.relative(includefile, project.directory())
                results:insert(includefile)
            end
        end
    end
    return results:to_array()
end

