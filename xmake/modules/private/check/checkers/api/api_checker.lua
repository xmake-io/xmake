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
import("private.check.checker")
import("private.utils.target", {alias = "target_utils"})

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

function _do_show(str, opt)
    _g.showed = _g.showed or {}
    local showed = _g.showed
    local infostr
    if str then
        infostr = string.format("%s: %s: %s", opt.sourcetips, opt.level_tips, str)
    else
        infostr = string.format("%s: %s: unknown %s value '%s'", opt.sourcetips, opt.level_tips, opt.apiname, opt.value)
    end
    if opt.probable_value then
        infostr = string.format("%s, it may be '%s'", infostr, opt.probable_value)
    end
    if not showed[infostr] then
        cprint(infostr)
        showed[infostr] = true
        return true
    end
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
    local sourceinfo = target:sourceinfo(apiname, value) or {}
    local sourcetips = sourceinfo.file or ""
    if sourceinfo.line then
        sourcetips = sourcetips .. ":" .. (sourceinfo.line or -1)
    end
    if #sourcetips == 0 then
        sourcetips = string.format("target(%s)", target:name())
    end

    -- get level tips
    local level_tips = "note"
    if level == "warning" then
        level_tips = "${color.warning}${text.warning}${clear}"
    elseif level == "error" then
        level_tips = "${color.error}${text.error}${clear}"
    end

    -- get probable value
    local probable_value
    if opt.valueset then
        probable_value = _get_most_probable_value(value, opt.valueset)
    end

    if apiname:endswith("s") then
        apiname = apiname:sub(1, #apiname - 1)
    end

    -- do show
    return (opt.show or _do_show)(opt.showstr, {
        apiname = apiname,
        sourcetips = sourcetips,
        level_tips = level_tips,
        value = value,
        probable_value = probable_value})
end

-- check target
function _check_target(target, apiname, valueset, level, opt)
    local target_valueset = valueset
    if type(opt.values) == "function" then
        local target_values = opt.values(target)
        if target_values then
            target_valueset = hashset.from(target_values)
        end
    end
    local values = target:get(apiname)
    for _, value in ipairs(values) do
        if opt.check then
            local ok, errors = opt.check(target, value)
            if not ok then
                local reported = _show(apiname, value, target, {
                    show = opt.show,
                    showstr = errors,
                    level = level})
                if reported then
                    checker.update_stats(level)
                end
            end
        elseif not target_valueset:has(value) then
            local reported = _show(apiname, value, target, {
                show = opt.show,
                valueset = target_valueset,
                level = level})
            if reported then
                checker.update_stats(level)
            end
        end
    end
end

-- check flag
-- @see https://github.com/xmake-io/xmake/issues/3594
function check_flag(target, toolinst, flagkind, flag)
    local extraconf = target:extraconf(flagkind)
    flag = target_utils.flag_belong_to_tool(target, flag, toolinst, extraconf)
    if flag then
        extraconf = extraconf and extraconf[flag]
        if not extraconf or not extraconf.force then
            return toolinst:has_flags(flag)
        end
    end
    return true
end

-- check api configuration in targets
function check_targets(apiname, opt)
    opt = opt or {}
    local level = opt.level or "warning"
    local valueset
    if opt.values and type(opt.values) ~= "function" then
        valueset = hashset.from(opt.values)
    else
        valueset = hashset.new()
    end
    if opt.target then
        _check_target(opt.target, apiname, valueset, level, opt)
    else
        for _, target in pairs(project.targets()) do
            _check_target(target, apiname, valueset, level, opt)
        end
    end
end
