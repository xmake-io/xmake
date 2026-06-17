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
import("core.project.project")
import("private.detect.check_targetnames")

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

-- get the selected target objects from the given target names
--
-- if explicit target names are given, the matching targets are returned (and checked).
-- otherwise it selects the default/all/group targets, e.g. the actions like
-- build/install/uninstall/package/format share the same selection rule.
--
-- @param targetnames  a list of target names, a single target name, or the magic "__all"/"__def"
-- @param opt          the options, e.g. {group_pattern = ..., all = false}
--
-- @return             the selected target objects (list)
--
function get_targets(targetnames, opt)
    opt = opt or {}

    -- select the explicitly given targets
    if type(targetnames) == "table" or (type(targetnames) == "string" and not targetnames:startswith("__")) then
        return assert(check_targetnames(targetnames))
    end

    -- otherwise select the default/all/group targets
    local targets = {}
    local all = opt.all or targetnames == "__all" or option.get("all")
    local group_pattern = opt.group_pattern
    for _, target in ipairs(project.ordertargets()) do
        local group = target:get("group")
        if (target:is_default() and not group_pattern) or all or (group_pattern and group and group:match(group_pattern)) then
            table.insert(targets, target)
        end
    end
    return targets
end
