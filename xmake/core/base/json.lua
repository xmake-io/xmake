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
-- @file        json.lua
--

-- define module: json
local json  = json or {}

-- load modules
local io    = require("base/io")
local os    = require("base/os")
local utils = require("base/utils")

-- export null
json.purenull = {}
setmetatable(json.purenull, {
    __is_json_null = true,
    __eq = function (obj)
        if type(obj) == "table" then
            local mt = getmetatable(obj)
            if mt and mt.__is_json_null then
                return true
            end
        end
        return false
    end,
    __tostring = function()
        return "null"
    end})
if cjson then
    json.null = cjson.null
else
    json.null = json.purenull
end

function json._pure_kind_of(obj)
    if type(obj) ~= "table" then
        return type(obj)
    end
    if json.is_marked_as_array(obj) then
        return "array"
    end
    if obj == json.purenull then
        return "nil"
    end
    local i = 1
    for _ in pairs(obj) do
        if obj[i] ~= nil then
            i = i + 1
        else
            return "table"
        end
    end
    if i == 1 then
        return "table"
    else
        return "array"
    end
end

function json._pure_escape_str(s)
    local in_char  = {'\\', '"', '/', '\b', '\f', '\n', '\r', '\t'}
    local out_char = {'\\', '"', '/',  'b',  'f',  'n',  'r',  't'}
    for i, c in ipairs(in_char) do
        s = s:gsub(c, '\\' .. out_char[i])
    end
    return s
end

function json._pure_skip_delim(str, pos, delim, err_if_missing)
    pos = pos + #str:match('^%s*', pos)
    if str:sub(pos, pos) ~= delim then
        if err_if_missing then
            os.raise("expected %s near position %d", delim, pos)
        end
        return pos, false
    end
    return pos + 1, true
end

function json._pure_parse_str_val(str, pos, val)
    val = val or ''
    local early_end_error = "end of input found while parsing string."
    if pos > #str then
        os.raise(early_end_error)
    end
    local c = str:sub(pos, pos)
    if c == '"'  then
        return val, pos + 1
    end
    if c ~= '\\' then
        return json._pure_parse_str_val(str, pos + 1, val .. c)
    end

    -- we must have a \ character.
    local esc_map = {b = '\b', f = '\f', n = '\n', r = '\r', t = '\t'}
    local nextc = str:sub(pos + 1, pos + 1)
    if not nextc then
        os.raise(early_end_error)
    end
    return json._pure_parse_str_val(str, pos + 2, val .. (esc_map[nextc] or nextc))
end

function json._pure_parse_num_val(str, pos)
    local num_str
    if str:sub(pos, pos + 1) == "0x" then
        num_str = str:match('^-?0[xX][0-9a-fA-F]+', pos)
    else
        num_str = str:match('^-?%d+%.?%d*[eE]?[+-]?%d*', pos)
    end
    local val = tonumber(num_str)
    if not val then
        os.raise("error parsing number at position %d", pos)
    end
    return val, pos + #num_str
end

function json._pure_stringify(obj, as_key)
    local s = {}
    local kind = json._pure_kind_of(obj)
    if kind == "array" then
        if as_key then
            os.raise("can\'t encode array as key.")
        end
        s[#s + 1] = '['
        for i, val in ipairs(obj) do
            if i > 1 then s[#s + 1] = ',' end
            s[#s + 1] = json._pure_stringify(val)
        end
        s[#s + 1] = ']'
    elseif kind == "table" then
        if as_key then
            os.raise("can\'t encode table as key.")
        end
        s[#s + 1] = '{'
        for k, v in pairs(obj) do
            if #s > 1 then s[#s + 1] = ',' end
            s[#s + 1] = json._pure_stringify(k, true)
            s[#s + 1] = ':'
            s[#s + 1] = json._pure_stringify(v)
        end
        s[#s + 1] = '}'
    elseif kind == "string" then
        return '"' .. json._pure_escape_str(obj) .. '"'
    elseif kind == "number" then
        if as_key then
            return '"' .. tostring(obj) .. '"'
        end
        return tostring(obj)
    elseif kind == "boolean" then
        return tostring(obj)
    elseif kind == "nil" then
        return "null"
    else
        os.raise("unknown type: %s", kind)
    end
    return table.concat(s)
end

function json._pure_parse(str, pos, end_delim)
    pos = pos or 1
    if pos > #str then
        os.raise("reached unexpected end of input.")
    end
    -- skip whitespace.
    local pos = pos + #str:match('^%s*', pos)
    local first = str:sub(pos, pos)
    if first == '{' then
        local obj, key, delim_found = {}, true, true
        pos = pos + 1
        while true do
            key, pos = json._pure_parse(str, pos, '}')
            if key == nil then
                return obj, pos
            end
            if not delim_found then
                os.raise("comma missing between object items.")
            end
            pos = json._pure_skip_delim(str, pos, ':', true)  -- true -> error if missing.
            obj[key], pos = json._pure_parse(str, pos)
            pos, delim_found = json._pure_skip_delim(str, pos, ',')
        end
    elseif first == '[' then
        local arr, val, delim_found = {}, true, true
        json.mark_as_array(arr)
        pos = pos + 1
        while true do
            val, pos = json._pure_parse(str, pos, ']')
            if val == nil then
                return arr, pos
            end
            if not delim_found then
                os.raise("comma missing between array items.")
            end
            arr[#arr + 1] = val
            pos, delim_found = json._pure_skip_delim(str, pos, ',')
        end
    elseif first == '"' then
        return json._pure_parse_str_val(str, pos + 1)
    elseif first == '-' or first:match("%d") then
        return json._pure_parse_num_val(str, pos)
    elseif first == end_delim then
        -- end of an object or array.
        return nil, pos + 1
    else
        local literals = {["true"] = true, ["false"] = false, ["null"] = json.purenull}
        for lit_str, lit_val in pairs(literals) do
            local lit_end = pos + #lit_str - 1
            if str:sub(pos, lit_end) == lit_str then
                return lit_val, lit_end + 1
            end
        end
        local pos_info_str = "position " .. pos .. ": " .. str:sub(pos, pos + 10)
        os.raise("invalid json syntax starting at " .. pos_info_str)
    end
end

-- decode json string using pure lua
function json._pure_decode(jsonstr, opt)
    return json._pure_parse(jsonstr)
end

-- encode json string using pua lua
function json._pure_encode(luatable, opt)
    return json._pure_stringify(luatable)
end

-- support empty array
-- @see https://github.com/mpx/lua-cjson/issues/11
function json.mark_as_array(luatable)
    local mt = getmetatable(luatable) or {}
    mt.__is_cjson_array = true
    return setmetatable(luatable, mt)
end

-- is marked as array?
function json.is_marked_as_array(luatable)
    local mt = getmetatable(luatable)
    return mt and mt.__is_cjson_array
end

-- decode json string to the lua table
--
-- @param jsonstr       the json string
-- @param opt           the options
--
-- @return              the lua table
--
function json.decode(jsonstr, opt)
    local decode = cjson and cjson.decode or json._pure_decode
    if opt and opt.pure then
        decode = json._pure_decode
    end
    local ok, luatable_or_errors = utils.trycall(decode, nil, jsonstr)
    if not ok then
        return nil, string.format("decode json failed, %s", luatable_or_errors)
    end
    return luatable_or_errors
end

-- encode lua table to the json string
--
-- @param luatable      the lua table
-- @param opt           the options
--
-- @return              the json string
--
function json.encode(luatable, opt)
    local encode = cjson and cjson.encode or json._pure_encode
    if opt and opt.pure then
        encode = json._pure_encode
    end
    local ok, jsonstr_or_errors = utils.trycall(encode, nil, luatable)
    if not ok then
        return nil, string.format("encode json failed, %s", jsonstr_or_errors)
    end
    return jsonstr_or_errors
end

-- load json file to the lua table
--
-- @param filepath      the json file path
-- @param opt           the options
--                      - encoding for io/file, e.g. utf8, utf16, utf16le, utf16be ..
--                      - continuation for io/read (concat string with the given continuation characters)
--
-- @return              the lua table
--
function json.loadfile(filepath, opt)
    local filedata, errors = io.readfile(filepath, opt)
    if not filedata then
        return nil, errors
    end
    return json.decode(filedata, opt)
end

-- save lua table to the json file
--
-- @param filepath      the json file path
-- @param luatable      the lua table
-- @param opt           the options
--                      - encoding for io/file, e.g. utf8, utf16, utf16le, utf16be ..
--
-- @return              the json string
--
function json.savefile(filepath, luatable, opt)
    local jsonstr, errors = json.encode(luatable, opt)
    if not jsonstr then
        return false, errors
    end
    return io.writefile(filepath, jsonstr, opt)
end

-- return module: json
return json
