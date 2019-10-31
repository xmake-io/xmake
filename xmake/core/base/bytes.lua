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
-- @author      ruki
-- @file        bytes.lua
--

-- define module: bytes
local bytes = bytes or {}
local _instance = _instance or {}

-- load modules
local bit = require('bit')
local ffi = require('ffi')
local os  = require("base/os")

-- define ffi interfaces
ffi.cdef[[
    void* malloc(size_t __size);
    void  free(void *__ptr);
]]

-- new a bytes instance
--
-- new(size): allocates a buffer of given size
-- new(size, ptr [, manage]) : mounts buffer on existing storage (manage memory or not)
-- new(str): allocates a buffer from the given string
--
function _instance.new(arg1, arg2, arg3)
    local instance = table.inherit(_instance)
    if type(arg1) == "number" then
        local size = arg1
        local ptr = arg2 
        if ptr then
            -- new(size, ptr [, manage]) : mounts buffer on existing storage (manage memory or not)
            local manage = arg3
            if manage then
                instance._CDATA   = ffi.gc(ffi.cast("unsigned char*", ptr), ffi.C.free)
                instance._MANAGED = true
            else
                instance._CDATA   = ffi.cast("unsigned char*", ptr)
                instance._MANAGED = false
            end
        else
            -- new(size): allocates a buffer of given size
            ptr = ffi.C.malloc(size)
            instance._CDATA   = ffi.gc(ffi.cast("unsigned char*", ptr), ffi.C.free)
            instance._MANAGED = true
        end
        instance._SIZE   = size
    elseif type(arg1) == "string" then
        -- new(str): allocates a buffer from the given string
        local str = arg1
        instance._SIZE    = #str
        instance._CDATA   = ffi.cast("unsigned char*", str)
        instance._REF     = str -- keep ref for GC
        instance._MANAGED = false
    else
        os.raise("invalid arguments for bytes(...)!")
    end
    setmetatable(instance, _instance)
    return instance
end

-- get bytes size
function _instance:size()
    return self._SIZE
end

-- bytes:ipairs()
function _instance:ipairs()
    local index = 0
    return function (...)
        if index < self:size() then
            index = index + 1
            return index, self[index]
        end
    end
end

-- bytes[key]
function _instance:__index(key)
    if type(key) == "number" then
        if key < 1 or key > self:size() then 
            os.raise("bytes index(%d/%d) out of bounds!", key, self:size()) 
        end
        return self._CDATA[key - 1]
    --[[
    elseif type(key) == "table" then
        local start, last = key[1], key[2]
        return self:slice(start, last)
    --]]
    end
    return rawget(self, key)
end

-- bytes[key] = value
function _instance:__newindex(key, value)
    if type(key) == "number" then
        if key < 1 or key > self:size() then 
            os.raise("bytes index(%d/%d) out of bounds!", key, self:size()) 
        end
        self._CDATA[key - 1] = value
        return
        --[[
    elseif type(key) == "table" then
        local start,last = key[1],key[2]
        self:slice(start,last):copy(value)
        return]]
    end
    rawset(self, key, value)
end

-- tostring(bytes)
function _instance:__tostring()
    local parts = {}
    for i = 1, tonumber(self:size()) do
        parts[i] = bit.tohex(self[i], 2)
    end
    return "<bytes: " .. table.concat(parts, " ") .. ">"
end

-- new an bytes instance
function bytes.new(...)
    return _instance.new(...)
end

-- register call function
setmetatable(bytes, {
    __call = function (_, ...) 
        return bytes.new(...) 
    end,
    __tostring = function()
        return "<bytes>"
    end
})

-- return module: bytes
return bytes
