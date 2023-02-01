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
-- @file        api_checker.lua
--

-- imports
import("core.base.option")
import("core.base.hashset")
import("core.project.project")

-- show result
function _show(apiname, value, target, opt)
    opt = opt or {}

    -- match level?
    local level = opt.level
    local level_option = option.get("level")
    if level_option and level_option ~= "all" and level_option ~= level then
        return
    end

    -- get source information
    local sourceinfo = (target:get("__sourceinfo_" .. apiname) or {})[value] or {}
    local sourcetips = sourceinfo.file or ""
    if sourceinfo.line then
        sourcetips = sourcetips .. ":" .. sourceinfo.line .. ": "
    end
    if #sourcetips == 0 then
        sourcetips = string.format("target(%s)", target:name())
    end

    -- do show
    local level_tips = "note"
    if level == "warning" then
        level_tips = "${color.warning}${text.warning}${clear}"
    elseif level == "error" then
        level_tips = "${color.error}${text.error}${clear}"
    end
    if apiname:endswith("s") then
        apiname = apiname:sub(1, #apiname - 1)
    end
    _g.showed = _g.showed or {}
    local showed = _g.showed
    local infostr = string.format("%s%s: unknown %s value '%s'", sourcetips, level_tips, apiname, value)
    if not showed[infostr] then
        cprint(infostr)
        showed[infostr] = true
    end
end

-- check api configuration in targets
function check_targets(apiname, opt)
    opt = opt or {}
    local valueset = hashset.from(opt.values)
    for _, target in pairs(project.targets()) do
        local values = target:get(apiname)
        for _, value in ipairs(values) do
            if not valueset:has(value) then
                _show(apiname, value, target, {level = "warning"})
            end
        end
    end
end
