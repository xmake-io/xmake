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
-- @author      OpportunityLiu
-- @file        todisplay.lua
--

-- define module
local todisplay = todisplay or {}

-- load modules
local colors  = require("base/colors")
local math    = require("base/math")


function todisplay._reset()
    local reset = todisplay._RESET
    if not reset then
        reset = colors.translate("${reset}")
        todisplay._RESET = reset
    end
    return reset
end

-- format string with theme colors
function todisplay._format(fmtkey, fmtdefault, ...)
    local theme = colors.theme()
    if theme then
        return colors.translate(string.format(theme:get(fmtkey), ...), { patch_reset = false, ignore_unknown = true })
    else
        return string.format(fmtdefault, ...)
    end
end

-- translate string with theme formats
function todisplay._translate(str)
    local theme = colors.theme()
    if theme then
        return colors.translate(str, { patch_reset = false, ignore_unknown = true })
    else
        return colors.ignore(str)
    end
end

-- print keyword
function todisplay._print_keyword(keyword)
    return todisplay._translate("${reset}${color.dump.keyword}") .. tostring(keyword) .. todisplay._reset()
end

-- print string
function todisplay._print_string(str, as_key)
    local quote = (not as_key) or (not str:match("^[a-zA-Z_][a-zA-Z0-9_]*$"))
    if quote then
        return todisplay._translate([[${reset}${color.dump.string_quote}"${reset}${color.dump.string}]])
            .. str
            .. todisplay._translate([[${reset}${color.dump.string_quote}"${reset}]])
    else
        return todisplay._translate("${reset}${color.dump.string}") .. str .. todisplay._reset()
    end
end

-- print number
function todisplay._print_number(num)
    return todisplay._translate("${reset}${color.dump.number}") .. tostring(num) .. todisplay._reset()
end

-- print function
function todisplay._print_function(func)
    local funcinfo = debug.getinfo(func)
    local srcinfo = funcinfo.short_src
    if funcinfo.linedefined >= 0 then
        srcinfo = srcinfo .. ":" .. funcinfo.linedefined
    end
    local funcname = funcinfo.name and (funcinfo.name .. " ") or ""
    return todisplay._translate("${reset}${color.dump.function}function ${bright}")
        .. funcname
        .. todisplay._translate("${reset}${dim}")
        .. srcinfo .. todisplay._reset()
end

function todisplay._get_tostr_method(value)
    local metatable = debug.getmetatable(value)
    if metatable then
        local __todisplay = rawget(metatable, "__todisplay")
        local __tostring = rawget(metatable, "__tostring")
        return __todisplay, __tostring
    end
    return nil, nil
end

-- print value with default format
function todisplay._print_default_scalar(value, style, formatkey)
    local __todisplay, __tostring = todisplay._get_tostr_method(value)
    if __todisplay then
        local ok, str = pcall(__todisplay, value)
        if ok then
            value = todisplay._translate(str)
            -- disable format
            formatkey = nil
        end
    elseif __tostring then
        local ok, str = pcall(__tostring, value)
        if ok then
            value = str
        end
    end
    if formatkey then
        value = todisplay._format(formatkey, "%s", value)
    end
    local reset = todisplay._reset()
    return reset .. todisplay._translate(style) .. value .. reset
end

-- print udata value with scalar format
function todisplay._print_udata_scalar(value)
    return todisplay._print_default_scalar(value, "${color.dump.udata}", "text.dump.udata_format")
end

-- print table value with scalar format
function todisplay._print_table_scalar(value, expand)
    if debug.getmetatable(value) or not expand then
        return todisplay._print_default_scalar(value, "${color.dump.table}", "text.dump.table_format")
    end
    local pvalues = {}
    local has_string_key = false
    local as, ae = math.huge, -math.huge

    local k, v
    for i = 1, 10 do
        k, v = next(value, k)
        if k == nil then break end

        if type(k) == "string" then
            pvalues[k] = todisplay._print_scalar(v, false)
            has_string_key = true
        elseif type(k) == "number" and math.isint(k) then
            pvalues[k] = todisplay._print_scalar(v, false)
            as = math.min(k, as)
            ae = math.max(k, ae)
        else
            -- no common table or array
            return todisplay._print_default_scalar(value, "${color.dump.table}", "text.dump.table_format")
        end
    end
    if k ~= nil then
        -- to large
        return todisplay._print_default_scalar(value, "${color.dump.table}", "text.dump.table_format")
    end

    local results = {}
    local is_arr = as >= 1 and ae <= 20
    if is_arr then
        local nilstr
        for i = 1, ae do
            local pv = pvalues[i]
            if pv == nil then
                if not nilstr then
                    nilstr = todisplay._print_keyword("nil")
                end
                pv = nilstr
            end
            results[i] = pv
        end
    end
    if has_string_key then
        for pk, pv in pairs(pvalues) do
            if type(pk) == "string" then
                local pkstr = todisplay._print_string(pk, true)
                table.insert(results, pkstr .. " = " .. pv)
            elseif not is_arr then
                local pkstr = todisplay._print_number(pk)
                table.insert(results, pkstr .. " = " .. pv)
            end
        end
    end
    if #results == 0 then
        return todisplay._translate("${reset}${color.dump.table}") .. "{ }" .. todisplay._reset()
    end
    return todisplay._translate("${reset}${color.dump.table}") .. "{ " .. table.concat(results, ", ") .." }" .. todisplay._reset()
end

-- print scalar value
function todisplay._print_scalar(value, expand)
    if type(value) == "nil" or type(value) == "boolean" then
        return todisplay._print_keyword(value)
    elseif type(value) == "number" then
        return todisplay._print_number(value)
    elseif type(value) == "string" then
        return todisplay._print_string(value)
    elseif type(value) == "function" then
        return todisplay._print_function(value)
    elseif type(value) == "userdata" then
        return todisplay._print_udata_scalar(value)
    elseif type(value) == "table" then
        return todisplay._print_table_scalar(value, expand)
    else
        return todisplay._print_default_scalar(value, "${color.dump.default}", "text.dump.default_format")
    end
end

function todisplay.print(value)
    return todisplay._print_scalar(value, true)
end

setmetatable(todisplay, {
    __call = function (_, ...)
        return todisplay.print(...)
    end
})

return todisplay
