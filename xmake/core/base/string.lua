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
-- @author      ruki
-- @file        string.lua
--

-- define module: string
local string = string or {}

-- load modules
local deprecated = require("base/deprecated")
local serialize  = require("base/serialize")

-- save original interfaces
string._dump = string._dump or string.dump
string._trim = string._trim or string.trim
string._split = string._split or string.split
string._lastof = string._lastof or string.lastof

-- find the last substring with the given pattern
function string:lastof(pattern, plain)

    -- is plain text? use the native implementation
    if plain then
        return string._lastof(self, pattern)
    end

    -- find the last substring
    local curr = 0
    repeat
        local next = self:find(pattern, curr + 1, plain)
        if next then
            curr = next
        end
    until (not next)

    -- found?
    if curr > 0 then
        return curr
    end
end

-- split string with the given substring/characters
--
-- pattern match and ignore empty string
-- ("1\n\n2\n3"):split('\n') => 1, 2, 3
-- ("abc123123xyz123abc"):split('123') => abc, xyz, abc
-- ("abc123123xyz123abc"):split('[123]+') => abc, xyz, abc
--
-- plain match and ignore empty string
-- ("1\n\n2\n3"):split('\n', {plain = true}) => 1, 2, 3
-- ("abc123123xyz123abc"):split('123', {plain = true}) => abc, xyz, abc
--
-- pattern match and contains empty string
-- ("1\n\n2\n3"):split('\n', {strict = true}) => 1, , 2, 3
-- ("abc123123xyz123abc"):split('123', {strict = true}) => abc, , xyz, abc
-- ("abc123123xyz123abc"):split('[123]+', {strict = true}) => abc, xyz, abc
--
-- plain match and contains empty string
-- ("1\n\n2\n3"):split('\n', {plain = true, strict = true}) => 1, , 2, 3
-- ("abc123123xyz123abc"):split('123', {plain = true, strict = true}) => abc, , xyz, abc
--
-- limit split count
-- ("1\n\n2\n3"):split('\n', {limit = 2}) => 1, 2\n3
-- ("1.2.3.4.5"):split('%.', {limit = 3}) => 1, 2, 3.4.5
--
function string:split(delimiter, opt)
    local limit, plain, strict
    if opt then
        limit = opt.limit
        plain = opt.plain
        strict = opt.strict
    end
    if plain then
        return string._split(self, delimiter, strict, limit)
    end
    local start = 1
    local result = {}
    local pos, epos = self:find(delimiter, start, plain)
    while pos do
        local substr = self:sub(start, pos - 1)
        if (#substr > 0) or strict then
            if limit and limit > 0 and #result + 1 >= limit then
                break
            end
            table.insert(result, substr)
        end
        start = epos + 1
        pos, epos = self:find(delimiter, start, plain)
    end
    if start <= #self then
        table.insert(result, self:sub(start))
    elseif strict and (not limit or #result < limit) then
        if start == #self + 1 then
            table.insert(result, "")
        end
    end
    return result
end

-- trim the spaces
function string:trim(trimchars)
    return string._trim(self, trimchars, 0)
end

-- trim the left spaces
function string:ltrim(trimchars)
    return string._trim(self, trimchars, -1)
end

-- trim the right spaces
function string:rtrim(trimchars)
    return string._trim(self, trimchars, 1)
end

-- encode: ' ', '=', '\"', '<'
function string:encode()
    return (self:gsub("[%s=\"<]", function (w) return string.format("%%%x", w:byte()) end))
end

-- decode: ' ', '=', '\"'
function string:decode()
    return (self:gsub("%%(%x%x)", function (w) return string.char(tonumber(w, 16)) end))
end

-- replace text
function string:replace(old, new, opt)
    if opt and opt.plain then
        local b, e = self:find(old, 1, true)
        if b == nil then
            return self, 0
        else
            local str, count = self:sub(e + 1):replace(old, new, opt)
            return (self:sub(1, b - 1) .. new .. str), count + 1
        end
    else
        return self:gsub(old, new)
    end
end

-- try to format
function string.tryformat(format, ...)

    -- attempt to format it
    local ok, str = pcall(string.format, format, ...)
    if ok then
        return str
    else
        return tostring(format)
    end
end

-- case-insensitive pattern-matching
--
-- print(("src/dadasd.C"):match(string.ipattern("sR[cd]/.*%.c", true)))
-- print(("src/dadasd.C"):match(string.ipattern("src/.*%.c", true)))
--
-- print(string.ipattern("sR[cd]/.*%.c"))
--   [sS][rR][cd]/.*%.[cC]
--
-- print(string.ipattern("sR[cd]/.*%.c", true))
--   [sS][rR][cCdD]/.*%.[cC]
--
function string.ipattern(pattern, brackets)
    local tmp = {}
    local i = 1
    while i <= #pattern do

        -- get current charactor
        local char = pattern:sub(i, i)

        -- escape?
        if char == '%' then
            tmp[#tmp + 1] = char
            i = i + 1
            char = pattern:sub(i,i)
            tmp[#tmp + 1] = char

            -- '%bxy'? add next 2 chars
            if char == 'b' then
                tmp[#tmp + 1] = pattern:sub(i + 1, i + 2)
                i = i + 2
            end
        -- brackets?
        elseif char == '[' then
            tmp[#tmp + 1] = char
            i = i + 1
            while i <= #pattern do
                char = pattern:sub(i, i)
                if char == '%' then
                    tmp[#tmp + 1] = char
                    tmp[#tmp + 1] = pattern:sub(i + 1, i + 1)
                    i = i + 1
                elseif char:match("%a") then
                    tmp[#tmp + 1] = not brackets and char or char:lower() .. char:upper()
                else
                    tmp[#tmp + 1] = char
                end
                if char == ']' then break end
                i = i + 1
            end
        -- letter, [aA]
        elseif char:match("%a") then
            tmp[#tmp + 1] = '[' .. char:lower() .. char:upper() .. ']'
        else
            tmp[#tmp + 1] = char
        end
        i = i + 1
    end
    return table.concat(tmp)
end

-- @deprecated
-- dump to string from the given object (more readable)
--
-- @param deflate       deflate empty characters
--
-- @return              string, errors
--
function string.dump(object, deflate)
    deprecated.add("utils.dump() or string.serialize()", "string.dump()")
    return string.serialize(object, deflate)
end

-- serialize to string from the given object
--
-- @param opt           serialize options
--                      e.g. { strip = true, binary = false, indent = true }
--
-- @return              string, errors
--
function string.serialize(object, opt)
    return serialize.save(object, opt)
end

-- deserialize string to object
--
-- @param str           the serialized string
--
-- @return              object, errors
--
function string:deserialize()
    return serialize.load(self)
end

-- return module: string
return string
