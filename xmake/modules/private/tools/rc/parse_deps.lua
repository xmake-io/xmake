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

-- normailize path of a dependecy
function _normailize_dep(dep, projectdir)

    -- tranlate dep path
    if path.is_absolute(dep) then
        dep = path.translate(dep)
    else
        dep = path.absolute(dep, projectdir)
    end

    -- save it if belong to the project
    if dep:startswith(projectdir) then
        return path.relative(dep, projectdir)
    end
end

-- parse depsfiles from string
function main(depsdata)
    local results = hashset.new()
    local projectdir = os.projectdir()
    for _, includefile in ipairs(depsdata:split('\n', {plain = true})) do
        if #includefile > 0 then
            includefile = _normailize_dep(includefile, projectdir)
            if includefile then
                results:insert(includefile)
            end
        end
    end
    return results:to_array()
end
