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
-- @file        check_targets.lua
--

-- imports
import("core.base.option")
import("core.project.project")
import("private.check.checker")
import("private.check.show")

function main(targetnames, opt)
    opt = opt or {}

    -- get targets
    local targets = {}
    if targetnames then
        for _, targetname in ipairs(table.wrap(targetnames)) do
            table.insert(targets, project.target(targetname))
        end
    else
        for _, target in pairs(project.targets()) do
            if target:is_enabled() then
                local group = target:get("group")
                if (target:is_default() and not group_pattern) or option.get("all") or (group_pattern and group and group:match(group_pattern)) then
                    table.insert(targets, target)
                end
            end
        end
    end

    -- do check
    local checkers = checker.checkers()
    for name, info in table.orderpairs(checkers) do
        if (info.build and opt.build) or (info.build_failure and opt.build_failure) then
            local check = import("private.check.checkers." .. name, {anonymous = true})
            for _, target in ipairs(targets) do
                check({target = target, show = show.wshow})
            end
        end
    end
end
