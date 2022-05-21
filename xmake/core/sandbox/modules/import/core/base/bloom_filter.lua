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

-- load modules
local utils        = require("base/utils")
local bloom_filter = require("base/bloom_filter")
local string       = require("base/string")
local raise        = require("sandbox/modules/raise")

-- define module
local sandbox_core_base_bloom_filter            = sandbox_core_base_bloom_filter or {}
local sandbox_core_base_bloom_filter_instance   = sandbox_core_base_bloom_filter_instance or {}

-- wrap bloom_filter
function _bloom_filter_wrap(filter)

    -- hook bloom_filter interfaces
    local hooked = {}
    for name, func in pairs(sandbox_core_base_bloom_filter_instance) do
        if not name:startswith("_") and type(func) == "function" then
            hooked["_" .. name] = filter["_" .. name] or filter[name]
            hooked[name] = func
        end
    end
    for name, func in pairs(hooked) do
        filter[name] = func
    end
    return filter
end

-- get bloom filter data
function sandbox_core_base_bloom_filter_instance.data(filter)
    local data, errors = filter:_data()
    if not data and errors then
        raise(errors)
    end
    return data
end

-- set bloom filter data
function sandbox_core_base_bloom_filter_instance.data_set(filter, data)
    local ok, errors = filter:_data_set(data)
    if not ok and errors then
        raise(errors)
    end
end

-- set bloom filter item
function sandbox_core_base_bloom_filter_instance.set(filter, item)
    local ok, result_or_errors = filter:_set(item)
    if not ok then
        raise(result_or_errors)
    end
    return result_or_errors
end

-- get bloom filter item
function sandbox_core_base_bloom_filter_instance.get(filter, item)
    local ok, result_or_errors = filter:_get(item)
    if not ok then
        raise(result_or_errors)
    end
    return result_or_errors
end

-- clear bloom filter data
function sandbox_core_base_bloom_filter_instance.clear(filter)
    local ok, errors = filter:_clear()
    if not ok then
        raise(errors)
    end
end

-- close bloom filter
function sandbox_core_base_bloom_filter_instance.close(filter)
    local ok, errors = filter:_close()
    if not ok then
        raise(errors)
    end
end

-- new bloom filter
function sandbox_core_base_bloom_filter.new(opt)
    local filter, errors = bloom_filter.new(opt)
    if not filter then
        raise(errors)
    end
    return _bloom_filter_wrap(filter)
end

-- return module
return sandbox_core_base_bloom_filter

