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
-- @author      OpportunityLiu
-- @file        complete_helper.lua
--

-- imports
import("core.project.project")
import("core.project.config")

-- get targets
function targets()
    return try
    {
        function ()
            config.load()
            return table.keys(project.targets())
        end
    }
end

-- get runnable targets
function runable_targets()
    return try
    {
        function ()
            config.load()
            local targets = project.targets()
            local runable = {}
            for k, v in pairs(targets) do
                if v:script("run") or v:is_binary() then
                    table.insert(runable, k)
                end
            end
            return runable
        end
    }
end
