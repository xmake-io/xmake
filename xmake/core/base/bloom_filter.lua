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
-- @file        bloom_filter.lua
--

-- define module: bloom_filter
local bloom_filter = bloom_filter or {}
local _instance = _instance or {}

-- load modules
local io    = require("base/io")
local utils = require("base/utils")
local bytes = require("base/bytes")
local table = require("base/table")

-- save metatable and builtin functions
bloom_filter._open     = bloom_filter._open or bloom_filter.open
bloom_filter._close    = bloom_filter._close or bloom_filter.close
bloom_filter._data     = bloom_filter._data or bloom_filter.data
bloom_filter._size     = bloom_filter._size or bloom_filter.size
bloom_filter._data_set = bloom_filter._data_set or bloom_filter.data_set
bloom_filter._clear    = bloom_filter._clear or bloom_filter.clear
bloom_filter._set      = bloom_filter._set or bloom_filter.set
bloom_filter._get      = bloom_filter._get or bloom_filter.get

-- the bloom filter probability
bloom_filter.PROBABILITY_0_1         = 3  -- 1 / 2^3 = 0.125 ~= 0.1
bloom_filter.PROBABILITY_0_01        = 6  -- 1 / 2^6 = 0.015625 ~= 0.01
bloom_filter.PROBABILITY_0_001       = 10 -- 1 / 2^10 = 0.0009765625 ~= 0.001
bloom_filter.PROBABILITY_0_0001      = 13 -- 1 / 2^13 = 0.0001220703125 ~= 0.0001
bloom_filter.PROBABILITY_0_00001     = 16 -- 1 / 2^16 = 0.0000152587890625 ~= 0.00001
bloom_filter.PROBABILITY_0_000001    = 20 -- 1 / 2^20 = 0.00000095367431640625 ~= 0.000001

-- new a bloom filter
function _instance.new(handle)
    local instance   = table.inherit(_instance)
    instance._HANDLE = handle
    setmetatable(instance, _instance)
    return instance
end

-- get cdata of the bloom filter
function _instance:cdata()
    return self._HANDLE
end

-- get the bloom filter data
function _instance:data()
    -- ensure opened
    local ok, errors = self:_ensure_opened()
    if not ok then
        return nil, errors
    end

    -- get the bloom filter data
    local data = bloom_filter._data(self:cdata())
    local size = bloom_filter._size(self:cdata())
    if not data or size == 0 then
        return nil, "no data!"
    end

    -- mount this data
    return bytes(size, data)
end

-- set the bloom filter data
function _instance:data_set(data)
    -- ensure opened
    local ok, errors = self:_ensure_opened()
    if not ok then
        return false, errors
    end

    -- set data
    local datasize = data:size()
    local dataaddr = data:caddr()
    if not dataaddr or datasize == 0 then
        return false, "empty data!"
    end
    return bloom_filter._data_set(self:cdata(), dataaddr, datasize)
end

-- clear the bloom filter data
function _instance:clear()
    -- ensure opened
    local ok, errors = self:_ensure_opened()
    if not ok then
        return false, errors
    end

    -- do clear
    return bloom_filter._clear(self:cdata())
end

-- set the bloom filter data item
--
--@code
-- if bloom_filter:set(item)) then
--     print("this data not exists, set ok!")
-- else
--     -- note: maybe false positives
--     print("this data have been existed, set failed!")
-- end
--@endcode
--
function _instance:set(item)

    -- ensure opened
    local ok, errors = self:_ensure_opened()
    if not ok then
        return false, errors
    end

    -- do set
    ok = bloom_filter._set(self:cdata(), item)
    return true, ok
end

-- get the bloom filter data item
--
--@code
-- if bloom_filter:get(item)) then
--     -- note: maybe false positives
--     print("this data have been existed, get ok!")
-- else
--     print("this data not exists, get failed!")
-- end
--@endcode
--
function _instance:get(item)

    -- ensure opened
    local ok, errors = self:_ensure_opened()
    if not ok then
        return false, errors
    end

    -- do get
    ok = bloom_filter._get(self:cdata(), item)
    return true, ok
end

-- ensure it is opened
function _instance:_ensure_opened()
    if not self:cdata() then
        return false, string.format("%s: has been closed!", self)
    end
    return true
end

-- tostring(bloom_filter)
function _instance:__tostring()
    return string.format("<bloom_filter: %s>", self:cdata())
end

-- gc(bloom_filter)
function _instance:__gc()
    if self:cdata() and bloom_filter._close(self:cdata()) then
        self._HANDLE = nil
    end
end

-- new a bloom filter, e.g. {probability = 0.001, hash_count = 3, item_maxn = 1000000}
function bloom_filter.new(opt)
    opt = opt or {}
    local probability = opt.probability or 0.001
    local maps = {
        [0.1] = bloom_filter.PROBABILITY_0_1,
        [0.01] = bloom_filter.PROBABILITY_0_01,
        [0.001] = bloom_filter.PROBABILITY_0_001,
        [0.0001] = bloom_filter.PROBABILITY_0_0001,
        [0.00001] = bloom_filter.PROBABILITY_0_00001,
        [0.000001] = bloom_filter.PROBABILITY_0_000001
    }
    probability = assert(maps[probability], "invalid probability(%f)", probability)
    local hash_count = opt.hash_count or 3
    local item_maxn = opt.item_maxn or 1000000
    local handle, errors = bloom_filter._open(probability, hash_count, item_maxn)
    if handle then
        return _instance.new(handle)
    else
        return nil, errors or "failed to open a bloom filter!"
    end
end

-- return module: bloom_filter
return bloom_filter
