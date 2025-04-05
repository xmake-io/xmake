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

