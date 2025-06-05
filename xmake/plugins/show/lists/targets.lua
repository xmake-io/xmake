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
-- @file        targets.lua
--

-- imports
import("core.base.option")
import("core.project.config")
import("core.project.project")
import("core.platform.platform")
import(".showlist")

-- show all targets (optionally filtered by group)
function main()
    config.load()

    local group_pattern = option.get("group") and ("^" .. path.pattern(option.get("group")) .. "$")
    local targets = {}

    for name, target in pairs(project.targets()) do
        local group = target:get("group")
        if (target:is_default() and not group_pattern) or
           (group_pattern and group and (function()
                for component in group:gmatch("[^/\\\\]+") do
                    if component:match(group_pattern) then return true end
                end
            end)()) then
            table.insert(targets, name)
        end
    end

    showlist(targets)
end
