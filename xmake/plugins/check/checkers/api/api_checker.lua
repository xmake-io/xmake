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
import("..checker")

-- get the most probable value
function _get_most_probable_value(value, valueset)
    local result
    local mindist
    for v in valueset:keys() do
        local dist = value:levenshtein(v)
        if not mindist or dist < mindist then
            mindist = dist
            result = v
        end
    end
    return result
end

-- show result
function _show(apiname, value, target, opt)
    opt = opt or {}

    -- match level? verbose: note/warning/error, default: warning/error
    local level = opt.level
    if not option.get("verbose") and level == "note" then
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
    local probable_value = _get_most_probable_value(value, opt.valueset)
    if probable_value then
        infostr = string.format("%s, it may be '%s'", infostr, probable_value)
    end
    if not showed[infostr] then
        cprint(infostr)
        showed[infostr] = true
        return true
    end
end

-- check api configuration in targets
function check_targets(apiname, opt)
    opt = opt or {}
    local level = opt.level or "warning"
    local valueset = hashset.from(opt.values)
    for _, target in pairs(project.targets()) do
        local values = target:get(apiname)
        for _, value in ipairs(values) do
            if not valueset:has(value) then
                local reported = _show(apiname, value, target, {valueset = valueset, level = level})
                if reported then
                    checker.update_stats(level)
                end
            end
        end
    end
end
