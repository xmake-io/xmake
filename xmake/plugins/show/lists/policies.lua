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
-- @author      A2va
-- @file        policies.lua
--

-- imports
import("core.project.policy")
import("core.base.json")
import("core.base.option")

-- show all policies
function main()
    local policies = policy.policies()
    if option.get("json") then
        local list = {}
        for name, policy in table.orderpairs(policies) do
            table.insert(list, {name = name, description = policy.description, default = policy.default or "false"})
        end
        print(json.encode(list))
        return 
    end

    local width = 45
    for name, policy in table.orderpairs(policies) do
        cprint("${color.dump.string}%s${clear}%s%s", name, (" "):rep(width - #name), policy["description"])
        cprint("%s${bright}%s", (" "):rep(width), policy["default"] or "false")
    end
end
