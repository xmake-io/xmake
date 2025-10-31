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
-- Copyright (C) 2015-present, Xmake Open Source Community.
--
-- @author      OpportunityLiu, ruki
-- @file        hashset.lua
--

-- load modules
local object    = require("base/object")
local table     = require("base/table")
local todisplay = require("base/todisplay")

-- define module
local hashset = hashset or object { _init = {"_DATA", "_SIZE"} }

-- representaion for nil key
hashset._NIL = setmetatable({}, {
    __todisplay = function()
        return "${reset}${color.dump.keyword}nil${reset}"
    end,
    __tostring = function()
        return "symbol(nil)"
    end
})

function hashset._to_key(key)
    if key == nil then
        key = hashset._NIL
    end
    return key
end

-- h1 == h1?
function hashset:__eq(h)
    if self._DATA == h._DATA then
        return true
    end
    if self:size() ~= h:size() then
        return false
    end
    for item in h:items() do
        if not self:has(item) then
            return false
        end
    end
    return true
end

-- to display
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

-- check value is in hashset
function hashset:has(value)
    value = hashset._to_key(value)
    return self._DATA[value] or false
end

-- insert value to hashset, returns false if value has already in the hashset
function hashset:insert(value)
    value = hashset._to_key(value)
    local result = not (self._DATA[value] or false)
    if result then
        self._DATA[value] = true
        self._SIZE = self._SIZE + 1
    end
    return result
end

-- insert the all values in array/hashset
function hashset:insert_all(values)
    if type(values) == "table" and values.items then
        for item in values:items() do
            self:insert(item)
        end
    else
        for _, item in ipairs(table.wrap(values)) do
            self:insert(item)
        end
    end
    return self
end

-- remove value from hashset, returns false if value is not in the hashset
function hashset:remove(value)
    value = hashset._to_key(value)
    local result = self._DATA[value] or false
    if result then
        self._DATA[value] = nil
        self._SIZE = self._SIZE - 1
    end
    return result
end

-- convert hashset to an array, nil in the set will be ignored
function hashset:to_array()
    local result = {}
    for item in self:items() do
        if item ~= nil then
            table.insert(result, item)
        end
    end
    return result
end

-- iterate items
--
-- @code
-- for item in instance:items() do
--   ...
-- end
-- @endcode
--
function hashset:items()
    return function (t, item)
        local k, _ = next(t._DATA, item)
        if k == hashset._NIL then
            return nil
        else
            return k
        end
    end, self, nil
end

-- iterate order items
--
-- @code
-- for item in instance:orderitems() do
--   ...
-- end
-- @endcode
--
function hashset:orderitems()
    local orderkeys = table.orderkeys(self._DATA, function (a, b)
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
            return nil
        else
            return k
        end
    end, self, nil
end

-- iterate keys (deprecated, please use items())
--
-- @code
-- for _, key in instance:keys() do
--   ...
-- end
-- @endcode
--
function hashset:keys()
    return function (t, key)
        local k, _ = next(t._DATA, key)
        if k == hashset._NIL then
            return k, nil
        else
            return k, k
        end
    end, self, nil
end

-- iterate order keys (deprecated, please use orderitems())
--
-- @code
-- for _, key in instance:orderkeys() do
--   ...
-- end
-- @endcode
--
function hashset:orderkeys()
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
function hashset:size()
    return self._SIZE
end

-- is empty?
function hashset:empty()
    return self:size() == 0
end

-- get data of hashset
function hashset:data()
    return self._DATA
end

-- clear hashset
function hashset:clear()
    self._DATA = {}
    self._SIZE = 0
end

-- clone hashset
function hashset:clone()
    local h = hashset.new()
    h._SIZE = self._SIZE
    h._DATA = table.clone(self._DATA)
    return h
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
    local result = hashset.new()
    for i = 1, #array do
        result:insert(array[i])
    end
    return result
end

-- new hashset
function hashset.new()
    return hashset {{}, 0}
end

-- return module: hashset
return hashset
