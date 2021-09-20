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
-- @file        dump.lua
--

-- define module
local dump = dump or {}

-- load modules
local todisplay = require("base/todisplay")

-- print string
function dump._print_string(str, as_key)
    io.write(todisplay._print_string(str, as_key))
end

-- print keyword
function dump._print_keyword(keyword)
    io.write(todisplay._print_keyword(keyword))
end

-- print function
function dump._print_function(func, as_key)
    if as_key then
        io.write(todisplay._translate("${reset}${color.dump.function}"),
            todisplay._format("text.dump.default_format", "%s", func),
            todisplay._translate("${reset}"))
    else
        io.write(todisplay._print_function(func))
    end
end

-- print scalar value
function dump._print_scalar(value, as_key)
    if type(value) == "string" then
        dump._print_string(value, as_key)
    elseif type(value) == "function" then
        dump._print_function(value, as_key)
    else
        io.write(todisplay._print_scalar(value))
    end
end

-- print anchor
function dump._print_anchor(printed_set_value)
    io.write(todisplay._translate("${color.dump.anchor}"),
        todisplay._format("text.dump.anchor", "&%s", printed_set_value.id),
        todisplay._translate("${reset}"))
end

-- print reference
function dump._print_reference(printed_set_value)
    io.write(todisplay._translate("${color.dump.reference}"),
        todisplay._format("text.dump.reference", "*%s", printed_set_value.id),
        todisplay._translate("${reset}"))
end

-- print anchor and store to printed_set
function dump._print_table_anchor(value, printed_set)
    io.write(" ")
    if printed_set[value].id then
        dump._print_anchor(printed_set[value])
        printed_set.refs[value] = printed_set[value]
    end
end

-- print metatable of value
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
            io.write(todisplay._translate("${reset} ${dim}=${reset} "))
            if funcname == "tostring" or funcname == "len" or funcname == "todisplay" then
                local ok, result = pcall(v, value, value)
                if ok then
                    if funcname == "todisplay" and type(result) == "string" then
                        io.write(todisplay._translate(result))
                    else
                        dump._print_scalar(result)
                    end
                    io.write(todisplay._translate("${dim} (evaluated)${reset}"))
                else
                    dump._print_scalar(v)
                end
            elseif v and printed_set.refs[v] then
                dump._print_reference(printed_set.refs[v])
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
            io.write(todisplay._translate("${reset} ${dim}=${reset} "))
            if v and printed_set.refs[v] then
                dump._print_reference(printed_set.refs[v])
            else
                dump._print_scalar(v)
            end
            io.write(",")
        end
    end
    return has_record
end

-- init printed_set
function dump._init_printed_set(printed_set, value)
    assert(type(value) == "table")
    for k, v in pairs(value) do
        if type(v) == "table" then
            -- has reference? v -> printed_set[v].obj
            if printed_set[v] then
                local obj = printed_set[v].obj
                if not printed_set[obj].id then
                    printed_set.id = printed_set.id + 1
                    printed_set[obj].id = printed_set.id
                end
            else
                printed_set[v] = {obj = v, name = k}
                dump._init_printed_set(printed_set, v)
            end
        end
    end
end

-- returns printed_set, is_first_level
function dump._get_printed_set(printed_set, value)
    local first_level = not printed_set
    if type(printed_set) ~= "table" then
        printed_set = {id = 0, refs = {}}
        if type(value) == "table" then
            printed_set[value] = {obj = value}
            dump._init_printed_set(printed_set, value)
        end
    end
    return printed_set, first_level
end

-- print udata
function dump._print_udata(value, first_indent, remain_indent, printed_set)

    local first_level
    local metatable = debug.getmetatable(value)
    printed_set, first_level = dump._get_printed_set(printed_set, metatable)
    io.write(first_indent)

    if not first_level then
        io.write(todisplay._print_udata_scalar(value))
    end
    local inner_indent = remain_indent .. "  "

    -- print open brackets
    io.write(todisplay._translate("${reset}${color.dump.udata}[${reset}"))

    -- print metatable
    local no_value = not dump._print_metatable(value, metatable, inner_indent, printed_set, false)

    -- print close brackets
    if no_value then
        io.write(todisplay._translate(" ${color.dump.udata}]${reset}"))
    else
        io.write("\b \n", remain_indent, todisplay._translate("${reset}${color.dump.udata}]${reset}"))
    end
end

-- print table
function dump._print_table(value, first_indent, remain_indent, printed_set)

    local first_level
    printed_set, first_level = dump._get_printed_set(printed_set, value)
    io.write(first_indent)
    local metatable = debug.getmetatable(value)
    local tostringmethod = metatable and (rawget(metatable, "__todisplay") or rawget(metatable, "__tostring"))
    if not first_level and tostringmethod then
        return dump._print_scalar(value)
    end

    local inner_indent = remain_indent .. "  "
    local first_value = true

    -- print open brackets
    io.write(todisplay._translate("${reset}${color.dump.table}{${reset}"))

    local function print_newline()
        if first_value then
            dump._print_table_anchor(value, printed_set)
            first_value = false
        end
        io.write("\n", inner_indent)
    end

    -- print metatable
    if first_level then
        first_value = not dump._print_metatable(value, metatable, inner_indent, printed_set, true)
    end

    -- print array items
    local is_arr = (value[1] ~= nil) and (table.maxn(value) < 2 * #value)
    if is_arr then
        for i = 1, table.maxn(value) do
            print_newline()
            local v = value[i]
            if type(v) == "table" then
                if printed_set.refs[v] then
                    dump._print_reference(printed_set.refs[v])
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
            io.write(todisplay._translate("${reset} ${dim}=${reset} "))
            if type(v) == "table" then
                if printed_set.refs[v] then
                    dump._print_reference(printed_set.refs[v])
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
        io.write(todisplay._translate(" ${color.dump.table}}${reset}"))
    else
        io.write("\b \n", remain_indent, todisplay._translate("${reset}${color.dump.table}}${reset}"))
    end
end

-- print value
function dump._print(value, indent, verbose)
    indent = tostring(indent or "")
    if type(value) == "table" then
        dump._print_table(value, indent, indent:gsub(".", " "), not verbose)
    elseif type(value) == "userdata" then
        dump._print_udata(value, indent, indent:gsub(".", " "), not verbose)
    else
        io.write(indent)
        dump._print_scalar(value)
    end
    io.write("\n")
end

return dump._print
