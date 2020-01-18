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
-- Copyright (C) 2015-2020, TBOOX Open Source Group.
--
-- @author      OpportunityLiu
-- @file        todisplay.lua
--

-- define module
local todisplay = todisplay or {}

-- load modules
local colors  = require("base/colors")

-- format string with theme colors
function todisplay._format(fmtkey, fmtdefault, ...)
    local theme = colors.theme()
    return string.format((theme and theme:get(fmtkey)) or fmtdefault, ...)
end

-- print keyword
function todisplay._print_keyword(keyword)
    return string.format("${reset}${color.dump.keyword}%s${reset}", keyword)
end

-- print string
function todisplay._print_string(str)
    return string.format([[${reset}${color.dump.string_quote}"${reset}${color.dump.string}%s${reset}${color.dump.string_quote}"${reset}]], str)
end

-- print number
function todisplay._print_number(num)
    return string.format("${reset}${color.dump.number}%s${reset}", num)
end

-- print function
function todisplay._print_function(func)
    local funcinfo = debug.getinfo(func)
    local srcinfo = funcinfo.short_src
    if funcinfo.linedefined >= 0 then
        srcinfo = srcinfo .. ":" .. funcinfo.linedefined
    end
    local funcname = funcinfo.name and (funcinfo.name .. " ") or ""
    return string.format("${reset}${color.dump.function}function ${bright}%s${reset}${dim}%s${reset}", funcname, srcinfo)
end

-- print value with default format
function todisplay._print_default_scalar(value, style, formatkey)
    local metatable = debug.getmetatable(value)
    if metatable then
        local __todisplay = rawget(metatable, "__todisplay")
        local __tostring = rawget(metatable, "__tostring")
        if __todisplay then
            local ok, str = pcall(__todisplay, value)
            if ok then
                value = str
                -- disable format
                formatkey = nil
            end
        elseif __tostring then
            local ok, str = pcall(__tostring, value)
            if ok then
                value = str
            end
        end
    end
    if formatkey then
        value = todisplay._format(formatkey, "%s", value)
    end
    return string.format("${reset}%s%s${reset}", style, value)
end

-- print udata value with scalar format
function todisplay._print_udata_scalar(value)
    return todisplay._print_default_scalar(value, "${color.dump.udata}", "text.dump.udata_format")
end

-- print table value with scalar format
function todisplay._print_table_scalar(value)
    return todisplay._print_default_scalar(value, "${color.dump.table}", "text.dump.table_format")
end

-- print scalar value
function todisplay._print_scalar(value)
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
        return todisplay._print_table_scalar(value)
    else
        return todisplay._print_default_scalar(value, "${color.dump.default}", "text.dump.default_format")
    end
end

return todisplay._print_scalar
