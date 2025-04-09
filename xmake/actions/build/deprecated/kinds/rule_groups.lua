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
-- @file        rule_groups.lua
--

-- imports
import("core.base.option")
import("core.project.rule")
import("core.project.config")
import("core.project.project")

-- get rule
-- @note we need to get rule from target first, because we maybe will inject and replace builtin rule in target
function get_rule(target, rulename)
    local ruleinst = assert(target:rule(rulename) or project.rule(rulename, {namespace = target:namespace()}) or
        rule.rule(rulename), "unknown rule: %s", rulename)
    return ruleinst
end

-- get max depth of rule
function _get_rule_max_depth(target, ruleinst, depth)
    local max_depth = depth
    for _, depname in ipairs(ruleinst:get("deps")) do
        local dep = get_rule(target, depname)
        local dep_depth = depth
        if ruleinst:extraconf("deps", depname, "order") then
            dep_depth = dep_depth + 1
        end
        local cur_depth = _get_rule_max_depth(target, dep, dep_depth)
        if cur_depth > max_depth then
            max_depth = cur_depth
        end
    end
    return max_depth
end

-- build sourcebatch groups for target
function _build_sourcebatch_groups_for_target(groups, target, sourcebatches)
    local group = groups[1]
    for _, sourcebatch in pairs(sourcebatches) do
        local rulename = assert(sourcebatch.rulename, "unknown rule for sourcebatch!")
        local item = group[rulename] or {}
        item.target = target
        item.sourcebatch = sourcebatch
        group[rulename] = item
    end
end

-- build sourcebatch groups for rules
function _build_sourcebatch_groups_for_rules(groups, target, sourcebatches)
    for _, sourcebatch in pairs(sourcebatches) do
        local rulename = assert(sourcebatch.rulename, "unknown rule for sourcebatch!")
        local ruleinst = get_rule(target, rulename)
        local depth = _get_rule_max_depth(target, ruleinst, 1)
        local group = groups[depth]
        if group == nil then
            group = {}
            groups[depth] = group
        end
        local item = group[rulename] or {}
        item.rule = ruleinst
        item.sourcebatch = sourcebatch
        group[rulename] = item
    end
end

-- build sourcebatch groups by rule dependencies order, e.g. `add_deps("qt.ui", {order = true})`
--
-- @see https://github.com/xmake-io/xmake/issues/2814
--
function build_sourcebatch_groups(target, sourcebatches)
    local groups = {{}}
    _build_sourcebatch_groups_for_target(groups, target, sourcebatches)
    _build_sourcebatch_groups_for_rules(groups, target, sourcebatches)
    if #groups > 0 then
        groups = table.reverse(groups)
    end
    return groups
end

