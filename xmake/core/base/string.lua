--!The Automatic Cross-platform Build Tool
-- 
-- XMake is free software; you can redistribute it and/or modify
-- it under the terms of the GNU Lesser General Public License as published by
-- the Free Software Foundation; either version 2.1 of the License, or
-- (at your option) any later version.
-- 
-- XMake is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU Lesser General Public License for more details.
-- 
-- You should have received a copy of the GNU Lesser General Public License
-- along with XMake; 
-- If not, see <a href="http://www.gnu.org/licenses/"> http://www.gnu.org/licenses/</a>
-- 
-- Copyright (C) 2015 - 2016, ruki All rights reserved.
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


-- return module: string
return string
