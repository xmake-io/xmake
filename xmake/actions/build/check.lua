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
-- @file        check_targets.lua
--

-- imports
import("core.base.option")
import("core.project.project")
import("private.check.checker")

function _show(str, opt)
    opt = opt or {}
    _g.showed = _g.showed or {}
    local showed = _g.showed
    local infostr
    if str and opt.sourcetips then
        infostr = string.format("%s${clear}: %s", opt.sourcetips, str)
    elseif opt.sourcetips and opt.apiname and opt.value ~= nil then
        infostr = string.format("%s${clear}: unknown %s value '%s'", opt.sourcetips, opt.apiname, opt.value)
    elseif str then
        infostr = string.format("${clear}: %s", str)
    end
    if opt.probable_value then
        infostr = string.format("%s, it may be '%s'", infostr, opt.probable_value)
    end
    if not showed[infostr] then
        wprint(infostr)
        showed[infostr] = true
    end
end

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
                check({target = target, show = _show})
            end
        end
    end
end
