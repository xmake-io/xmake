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
-- Copyright (C) 2015-present, Xmake Open Source Community.
--
-- @author      ruki
-- @file        buildmodes.lua
--

-- imports
import("core.project.config")
import("core.project.project")
import("core.project.rule")
import(".showlist")

-- show all platforms
function main()
    config.load()
    local modes = {}

    -- prioritize project modes
    local project_modes = nil
    if os.isfile(os.projectfile()) then
        project_modes = project.modes()
    end
    if project_modes and #project_modes > 0 then
        modes = project_modes
    else
        -- fallback to rule modes
        for _, r in pairs(rule.rules()) do
            local rulename = r:name()
            if rulename:startswith("mode.") then
                table.insert(modes, rulename:sub(6)) -- remove "mode." prefix
            end
        end
    end
    showlist(modes)
end
