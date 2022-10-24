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
-- @file        hashset.lua
--

-- define module
local hashset      = hashset or {}
local hashset_impl = hashset.__index or {}

-- load modules
local table      = require("base/table")
local todisplay  = require("base/todisplay")

-- representaion for nil key
hashset._NIL = setmetatable({}, { __todisplay = function() return "${reset}${color.dump.keyword}nil${reset}" end, __tostring = function() return "symbol(nil)" end })

function hashset:__todisplay()
    return string.format("hashset${reset}(%s) {%s}", todisplay(self._SIZE), table.concat(table.imap(table.keys(self._DATA), function (i, k)
        if i > 10 then
            return nil
        elseif i == 10 and self._SIZE ~= 10 then
            return "..."
        else
            return todisplay(k)
        end
    end), ", "))
end

function hashset._to_key(key)
    if key == nil then
        key = hashset._NIL
    end
    return key
end

-- make a new hashset
function hashset.new()
    return setmetatable({ _DATA = {}, _SIZE = 0 }, hashset)
end

-- construct from list of items
function hashset.of(...)
    local result = hashset.new()
    local data = table.pack(...)
    for i = 1, data.n do
        result:insert(data[i])
    end
    return result
end

-- construct from an array
function hashset.from(array)
    assert(array)
    return hashset.of(table.unpack(array))
end

-- check value is in hashset
function hashset_impl:has(value)
    value = hashset._to_key(value)
    return self._DATA[value] or false
end

-- insert value to hashset, returns false if value has already in the hashset
function hashset_impl:insert(value)
    value = hashset._to_key(value)
    local result = not (self._DATA[value] or false)
    if result then
        self._DATA[value] = true
        self._SIZE = self._SIZE + 1
    end
    return result
end

-- remove value from hashset, returns false if value is not in the hashset
function hashset_impl:remove(value)
    value = hashset._to_key(value)
    local result = self._DATA[value] or false
    if result then
        self._DATA[value] = nil
        self._SIZE = self._SIZE - 1
    end
    return result
end

-- convert hashset to an array, nil in the set will be ignored
function hashset_impl:to_array()
    local result = {}
    for k, _ in pairs(self._DATA) do
        if k ~= hashset._NIL then
            table.insert(result, k)
        end
    end
    return result
end

-- iterate keys of hashtable
--
-- @code
-- for _, key in instance:keys() do
--   ...
-- end
-- @endcode
--
function hashset_impl:keys()
    return function (t, key)
        local k, _ = next(t._DATA, key)
        if k == hashset._NIL then
            return k, nil
        else
            return k, k
        end
    end, self, nil
end

-- order keys iterator
--
-- @code
-- for _, key in instance:orderkeys() do
--   ...
-- end
-- @endcode
--
function hashset_impl:orderkeys()
    local orderkeys = table.keys(self._DATA)
    table.sort(orderkeys, function (a, b)
        if a == hashset._NIL then
            a = math.inf
        end
        if b == hashset._NIL then
            b = math.inf
        end
        if type(a) == "table" then
            a = tostring(a)
        end
        if type(b) == "table" then
            b = tostring(b)
        end
        return a < b
    end)
    local i = 1
    return function (t, k)
        k = orderkeys[i]
        i = i + 1
        if k == hashset._NIL then
            return k, nil
        else
            return k, k
        end
    end, self, nil
end

-- get size of hashset
function hashset_impl:size()
    return self._SIZE
end

-- is empty?
function hashset_impl:empty()
    return self:size() == 0
end

-- get data of hashset
function hashset_impl:data()
    return self._DATA
end

-- clear hashset
function hashset_impl:clear()
    self._DATA = {}
    self._SIZE = 0
end

-- return module
hashset.__index = hashset_impl
return hashset
