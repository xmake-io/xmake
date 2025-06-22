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
-- @file        target_utils.lua
--

-- imports
import("core.project.project")
import("core.base.option")

-- get project targets
function get_project_targets()
    local selected_target = option.get("target")
    if selected_target then
        -- return table.wrap(project.target(selected_target))
        return { project.target(selected_target) }
    end
    return project.targets()
end
