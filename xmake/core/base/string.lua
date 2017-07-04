--!The Make-like Build Utility based on Lua
--
-- Licensed to the Apache Software Foundation (ASF) under one
-- or more contributor license agreements.  See the NOTICE file
-- distributed with this work for additional information
-- regarding copyright ownership.  The ASF licenses this file
-- to you under the Apache License, Version 2.0 (the
-- "License"); you may not use this file except in compliance
-- with the License.  You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- 
-- Copyright (C) 2015 - 2017, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        string.lua
--

-- define module: string
local string = string or {}

-- find the last substring with the given pattern
function string:find_last(pattern, plain)

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

-- split string with the given characters
function string:split(chars)

    -- split it
    local list = {}
    self:gsub("[^" .. chars .."]+", function(v) table.insert(list, v) end )
    return list
end

-- trim the spaces
function string:trim()
    return (self:gsub("^%s*(.-)%s*$", "%1"))
end

-- trim the left spaces
function string:ltrim()
    return (self:gsub("^%s*", ""))
end

-- trim the right spaces
function string:rtrim()
    local n = #self
    while n > 0 and s:find("^%s", n) do n = n - 1 end
    return self:sub(1, n)
end

-- append a substring with a given separator
function string:append(substr, separator)

    -- check
    assert(self)

    -- not substr? return self
    if not substr then
        return self
    end

    -- append it
    local s = self
    if #s == 0 then
        s = substr
    else
        s = string.format("%s%s%s", s, separator or "", substr)
    end
    
    -- ok
    return s
end

-- encode: ' ', '=', '\"', '<'
function string:encode()

    -- null?
    if self == nil then return end

    -- done
    return (self:gsub("[%s=\"<]", function (w) return string.format("%%%x", w:byte()) end))
end

-- decode: ' ', '=', '\"'
function string:decode()

    -- null?
    if self == nil then return end

    -- done
    return (self:gsub("%%(%x%x)", function (w) return string.char(tonumber(w, 16)) end))
end

-- join array to string with the given separator
function string.join(items, sep)

    -- join them
    local str = ""
    local index = 1
    local count = #items
    for _, item in ipairs(items) do
        str = str .. item
        if index ~= count and sep ~= nil then
            str = str .. sep
        end
        index = index + 1
    end

    -- ok?
    return str
end

-- try to format
function string.tryformat(format, ...)

    -- attempt to format it
    local ok, str = pcall(string.format, format, ...)
    if ok then
        return str
    else
        return format
    end
end

-- return module: string
return string
