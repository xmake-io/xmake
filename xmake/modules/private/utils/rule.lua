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
-- @file        rule.lua
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

-- build rules orders in jobgraph, we need to add rule job with groups
--
-- like this:
-- @code
--   local root_group = ""
--   for _, ruleinst in ipairs(rules) do
--        local script_group = root_group .. "/" .. ruleinst:fullname()
--        jobgraph:group(script_group, function ()
--            jobgraph:add("xxx", function (index, total, opt)
--                -- call rule script
--            end)
--        end)
--    end
--
function build_orders_in_jobgraph(jobgraph, target, rules, opt)
    opt = opt or {}
    local root_group = assert(opt.root_group)
    for _, ruleinst in ipairs(rules) do
        local orders = table.wrap(ruleinst:get("orders"))
        if #orders > 0 then
            for _, order in ipairs(orders) do
                local joborders = {}
                for _, rulename in ipairs(order) do
                    -- we need to use fullname to support namespace
                    local ruleinst = get_rule(target, rulename)
                    local script_group = root_group .. "/" .. ruleinst:fullname()
                    if jobgraph:has(script_group) then
                        table.insert(joborders, script_group)
                    end
                end
                if #joborders > 0 then
                    jobgraph:add_orders(joborders)
                end
            end
        end
    end
end

