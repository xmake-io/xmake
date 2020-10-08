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
-- @file        parse_deps_json.lua
--

-- imports
import("core.project.project")
import("core.base.hashset")
import("core.base.json")

-- parse depsfiles from string
function main(depsdata)

    -- decode json data first
    depsdata = json.decode(depsdata)

    -- get includes
    local includes
    if depsdata and depsdata.Data then
        includes = depsdata.Data.Includes
    end

    -- translate it
    local results = hashset.new()
    local projectdir = os.projectdir():lower() -- we need generate lower string, because json values are all lower
    for _, includefile in ipairs(includes) do

        -- get the absolute path
        if not path.is_absolute(includefile) then
            includefile = path.absolute(includefile, projectdir):lower()
        end

        -- save it if belong to the project
        if includefile:startswith(projectdir) then
            -- insert it and filter repeat
            includefile = path.relative(includefile, projectdir)
            results:insert(includefile)
        end
    end
    return results:to_array()
end

