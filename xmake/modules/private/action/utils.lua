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
    local group_pattern = option.get("group")
    if group_pattern then
        group_pattern = "^" .. path.pattern(group_pattern) .. "$"
    else
        targetname = option.get("target")
    end
    return targetname, group_pattern
end

-- get target names and group pattern from option
--
-- it supports building multiple targets, e.g. `xmake build target1 target2 ...`
-- and is compatible with the legacy single `target` option passed programmatically.
--
function get_targets_and_group()
    local targetnames
    local group_pattern = option.get("group")
    if group_pattern then
        group_pattern = "^" .. path.pattern(group_pattern) .. "$"
    else
        targetnames = option.get("targets")
        if not targetnames then
            local targetname = option.get("target")
            if targetname then
                targetnames = {targetname}
            end
        end
        if targetnames then
            targetnames = table.wrap(targetnames)
        end
    end
    return targetnames, group_pattern
end
