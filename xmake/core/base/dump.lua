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
-- @author      OpportunityLiu
-- @file        dump.lua
--

-- define module
local dump = dump or {}

-- load modules
local colors  = require("base/colors")
local table   = require("base/table")

-- format string with theme colors
function dump._format(fmtkey, fmtdefault, ...)
    local theme = colors.theme()
    local fmt = theme and theme:get(fmtkey) or fmtdefault
    return string.format(fmt, ...)
end

-- print string
function dump._print_string(str, as_key)
    local quote = (not as_key) or (not str:match("^[a-zA-Z_][a-zA-Z0-9_]*$"))
    if quote then
        io.write(colors.translate("${reset}${color.dump.string_quote}\"${reset}${color.dump.string}", { patch_reset = false }))
    else
        io.write(colors.translate("${reset}${color.dump.string}", { patch_reset = false }))
    end
    io.write(str)
    if quote then
        io.write(colors.translate("${reset}${color.dump.string_quote}\"${reset}", { patch_reset = false }))
    else
        io.write(colors.translate("${reset}", { patch_reset = false }))
    end
end

-- print keyword
function dump._print_keyword(keyword)
    io.write(colors.translate("${color.dump.keyword}" .. tostring(keyword)))
end

-- print number
function dump._print_number(num)
    io.write(colors.translate("${color.dump.number}" .. tostring(num)))
end

-- print function
function dump._print_function(func, as_key)
    if as_key then
        return dump._print_default(func)
    end
    local funcinfo = debug.getinfo(func)
    local srcinfo = funcinfo.short_src
    if funcinfo.linedefined >= 0 then
        srcinfo = srcinfo .. ":" .. funcinfo.linedefined
    end
    io.write(colors.translate("${color.dump.function}function ${bright}" .. (funcinfo.name or "") .. "${reset}${dim}" .. srcinfo))
end

-- print value with default format
function dump._print_default(value)
    io.write(colors.translate("${color.dump.default}", { patch_reset = false }))
    io.write(dump._format("text.dump.default_format", "%s", value))
    io.write(colors.translate("${reset}", { patch_reset = false }))
end

-- print scalar value
function dump._print_scalar(value, as_key)
    if type(value) == "nil" then
        dump._print_keyword("nil")
    elseif type(value) == "boolean" then
        dump._print_keyword(value)
    elseif type(value) == "number" then
        dump._print_number(value)
    elseif type(value) == "string" then
        dump._print_string(value, as_key)
    elseif type(value) == "function" then
        dump._print_function(value, as_key)
    else
        dump._print_default(value)
    end
end

-- print anchor
function dump._print_anchor(value)
    io.write(colors.translate("${color.dump.anchor}", { patch_reset = false }))
    io.write(dump._format("text.dump.anchor", "&%s", value))
    io.write(colors.translate("${reset}", { patch_reset = false }))
end
-- print reference
function dump._print_reference(value)
    io.write(colors.translate("${color.dump.reference}", { patch_reset = false }))
    io.write(dump._format("text.dump.reference", "*%s", value))
    io.write(colors.translate("${reset}", { patch_reset = false }))
end

function dump._print_table_anchor(value, printed_set)
    printed_set.len = printed_set.len + 1
    io.write(" ")
    dump._print_anchor(printed_set.len)
    printed_set[value] = printed_set.len
end

function dump._print_metatable(value, metatable, inner_indent, printed_set, print_archor)
    if not metatable then
        return false
    end

    -- print metamethods
    local has_record = false
    local has_index_table = false
    for k, v in pairs(metatable) do
        if k == "__index" and type(v) == "table" then
            has_index_table = true
        elseif k:startswith("__") then
            if not has_record then
                has_record = true
                if print_archor then
                    dump._print_table_anchor(value, printed_set)
                end
            end
            io.write("\n", inner_indent)
            local funcname = k:sub(3)
            dump._print_keyword(funcname)
            io.write(colors.translate("${dim} = "))
            if funcname == "tostring" or funcname == "len" then
                local ok, result = pcall(v, value, value)
                if ok then
                    dump._print_scalar(result)
                    io.write(" (evaluated)")
                else
                    dump._print_scalar(v)
                end
            elseif v and printed_set[v] then
                dump._print_reference(printed_set[v])
            else
                dump._print_scalar(v)
            end
            io.write(",")
        end
    end

    if not has_index_table then
        return has_record
    end

    -- print index methods
    local index_table = metatable and rawget(metatable, "__index")
    for k, v in pairs(index_table) do
        -- hide private interfaces
        if type(k) ~= "string" or not k:startswith("_") then
            if not has_record then
                has_record = true
                if print_archor then
                    dump._print_table_anchor(value, printed_set)
                end
            end
            io.write("\n", inner_indent)
            dump._print_keyword("(")
            dump._print_scalar(k, true)
            dump._print_keyword(")")
            io.write(colors.translate("${dim} = "))
            if v and printed_set[v] then
                dump._print_reference(printed_set[v])
            else
                dump._print_scalar(v)
            end
            io.write(",")
        end
    end
    return has_record
end

-- print udata
function dump._print_udata(value, first_indent, remain_indent)

    io.write(first_indent)
    local metatable = getmetatable(value)
    local inner_indent = remain_indent .. "  "

    -- print open brackets
    io.write(colors.translate("${dim}["))

    -- print metatable
    local no_value = not dump._print_metatable(value, metatable, inner_indent, { len = 0 }, false)

    -- print close brackets
    if no_value then
        io.write(colors.translate(" ${dim}]"))
    else
        io.write("\b \n" .. remain_indent .. colors.translate("${dim}]"))
    end
end

-- print table
function dump._print_table(value, first_indent, remain_indent, printed_set)

    local first_level = not printed_set
    io.write(first_indent)
    local metatable = getmetatable(value)
    local tostringmethod = metatable and rawget(metatable, "__tostring")
    if not first_level and tostringmethod then
        local ok, strrep = pcall(tostringmethod, value, value)
        if ok then
            return dump._print_default(strrep)
        end
    end
    printed_set = printed_set or { len = 0 }
    local inner_indent = remain_indent .. "  "
    local first_value = true

    -- print open brackets
    io.write(colors.translate("${dim}{"))

    local function print_newline()
        if first_value then
            dump._print_table_anchor(value, printed_set)
            first_value = false
        end
        io.write("\n", inner_indent)
    end

    if first_level then
        first_value = not dump._print_metatable(value, metatable, inner_indent, printed_set, true)
    end

    -- print array items
    local is_arr = table.is_array(value) and (table.maxn(value) < 2 * #value)
    if is_arr then
        for i = 1,table.maxn(value) do
            print_newline()
            local v = value[i]
            if type(v) == "table" then
                if printed_set[v] then
                    dump._print_reference(printed_set[v])
                else
                    dump._print_table(v, "", inner_indent, printed_set)
                end
            else
                dump._print_scalar(v)
            end
            io.write(",")
        end
    end

    -- print data
    for k, v in pairs(value) do
        if not is_arr or type(k) ~= "number" then
            print_newline()
            dump._print_scalar(k, true)
            io.write(colors.translate("${dim} = "))
            if type(v) == "table" then
                if printed_set[v] then
                    dump._print_reference(printed_set[v])
                else
                    dump._print_table(v, "", inner_indent, printed_set)
                end
            else
                dump._print_scalar(v)
            end
            io.write(",")
        end
    end

    -- print close brackets
    if first_value then
        io.write(colors.translate(" ${dim}}"))
    else
        io.write("\b \n" .. remain_indent .. colors.translate("${dim}}"))
    end
end

-- print value
function dump._print(value, indent)
    indent = tostring(indent or "")
    if type(value) == "table" then
        dump._print_table(value, indent, indent:gsub(".", " "), nil)
    elseif type(value) == "userdata" then
        dump._print_udata(value, indent, indent:gsub(".", " "))
    else
        io.write(indent)
        dump._print_scalar(value)
    end
end

return dump._print
