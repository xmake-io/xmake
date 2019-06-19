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
-- Copyright (C) 2015 - 2019, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        utils.lua
--

-- define module
local dump = dump or {}

-- load modules
local colors  = require("base/colors")
local table   = require("base/table")


function dump._string(str, as_key)
    local quote = (not as_key) or (not str:match("^[a-zA-Z_][a-zA-Z0-9_]*$"))
    if quote then
        io.write(colors.translate("${color.dump.string}\""))
    end
    io.write(colors.translate("${reset}${color.dump.string bright}", { patch_reset = false }))
    io.write(str)
    io.write(colors.translate("${reset}", { patch_reset = false }))
    if quote then
        io.write(colors.translate("${color.dump.string}\""))
    end
end

function dump._keyword(keyword)
    io.write(colors.translate("${color.dump.keyword}" .. tostring(keyword)))
end

function dump._number(num)
    io.write(colors.translate("${color.dump.number}" .. num))
end

function dump._function(func, as_key)
    if as_key then
        return dump._default(func)
    end
    local funcinfo = debug.getinfo(func)
    local srcinfo = funcinfo.short_src
    if funcinfo.linedefined >= 0 then
        srcinfo = srcinfo .. ":" .. funcinfo.linedefined
    end
    io.write(colors.translate("${color.dump.function}function ${bright}" .. (funcinfo.name or "") .. "${reset}${dim}" .. srcinfo))
end

function dump._default(value)
    io.write(colors.translate("${dim}<", { patch_reset = false }))
    io.write(tostring(value))
    io.write(colors.translate(">${reset}", { patch_reset = false }))
end

function dump._scalar(value, as_key)
    if type(value) == "nil" then
        dump._keyword("nil")
    elseif type(value) == "boolean" then
        dump._keyword(value)
    elseif type(value) == "number" then
        dump._number(value)
    elseif type(value) == "string" then
        dump._string(value, as_key)
    elseif type(value) == "function" then
        dump._function(value, as_key)
    else
        dump._default(value)
    end
end

function dump._table(value, first_indent, remain_indent)
    io.write(first_indent .. colors.translate("${dim}{"))
    local inner_indent = remain_indent .. "  "
    local is_arr = table.is_array(value)
    local first_value = true
    for k, v in pairs(value) do
        if first_value then
            io.write("\n")
            first_value = false
        else
            io.write(",\n")
        end
        io.write(inner_indent)
        if not is_arr then
            dump._scalar(k, true)
            io.write(colors.translate("${dim} = "))
        end
        if type(v) == "table" then
            dump._table(v, "", inner_indent)
        else
            dump._scalar(v)
        end
    end
    if first_value then
        io.write(colors.translate(" ${dim}}"))
    else
        io.write("\n" .. remain_indent .. colors.translate("${dim}}"))
    end
end

function dump._print(value, indent)
    indent = indent or ""

    if type(value) == "table" then
        dump._table(value, indent, indent:gsub(".", " "))
    else
        io.write(indent)
        dump._scalar(value)
    end
end

return dump._print