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
-- @file        utils.lua
--

-- imports
import("core.base.option")

-- get target name and group pattern from option
function get_target_and_group()
    local targetname
    local group_pattern
    if option.get("group") then
        group_pattern = {}
        for _, elem in ipairs(option.get("group")) do
            table.insert(group_pattern, "^" .. path.pattern(elem) .. "$")
        end
    else
        targetname = option.get("target")
    end
    return targetname, group_pattern
end

-- determine if any of the pattern matches the name
function any_match(group_pattern, group)
    for _, pattern in ipairs(group_pattern) do
        if group:match(pattern) then
            return true
        end
    end
    return false
end
