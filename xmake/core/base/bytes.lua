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
    void* xm_ffi_malloc(unsigned long size);
    void  xm_ffi_free(void* data);
]]

-- new a bytes instance
--
-- bytes(size): allocates a buffer of given size
-- bytes(size, ptr [, manage]): mounts buffer on existing storage (manage memory or not)
-- bytes(str): mounts a buffer from the given string
-- bytes(bytes, start, last): mounts a buffer from another one, with start/last limits
-- bytes(bytes1, bytes2, bytes3, ...): allocates and concat buffer from list of byte buffers
-- bytes(bytes): allocates a buffer from another one (strict replica, sharing memory)
--
function _instance.new(...)
    local args = {...}
    local arg1, arg2, arg3 = unpack(args)
    local instance = table.inherit(_instance)
    if type(arg1) == "number" then
        local size = arg1
        local ptr = arg2 
        if ptr then
            -- bytes(size, ptr [, manage]): mounts buffer on existing storage (manage memory or not)
            local manage = arg3
            if manage then
                instance._CDATA   = ffi.gc(ffi.cast("unsigned char*", ptr), ffi.C.xm_ffi_free)
                instance._MANAGED = true
            else
                instance._CDATA   = ffi.cast("unsigned char*", ptr)
                instance._MANAGED = false
            end
        else
            -- bytes(size): allocates a buffer of given size
            ptr = ffi.C.xm_ffi_malloc(size)
            instance._CDATA   = ffi.gc(ffi.cast("unsigned char*", ptr), ffi.C.xm_ffi_free)
            instance._MANAGED = true
        end
        instance._SIZE   = size
    elseif type(arg1) == "string" then
        -- bytes(str): mounts a buffer from the given string
        local str = arg1
        instance._SIZE    = #str
        instance._CDATA   = ffi.cast("unsigned char*", str)
        instance._REF     = str -- keep ref for GC
        instance._MANAGED = false
    elseif type(arg1) == "table" then
        if type(arg2) == 'number' then
            -- bytes(bytes, start, last): mounts a buffer from another one, with start/last limits:
            local b = arg1
            local start = arg2 or 1
            local last = arg3 or b:size()
            if start < 1 or last > b:size() then
                os.raise("incorrect bounds(%d-%d) for bytes(...)!", start, last)
            end
            instance._SIZE    = last - start + 1
            instance._CDATA   = b:cdata() - 1 + start
            instance._REF     = b -- keep lua ref for GC
            instance._MANAGED = false
        elseif type(arg2) == "table" then
            -- bytes(bytes1, bytes2, bytes3, ...): allocates and concat buffer from list of byte buffers
            instance._SIZE = 0
            for _, b in ipairs(args) do
                instance._SIZE = instance._SIZE + b:size()
            end
            instance._CDATA = ffi.gc(ffi.cast("unsigned char*", ffi.C.xm_ffi_malloc(instance._SIZE)), ffi.C.xm_ffi_free)
            local offset = 0
            for _, b in ipairs(args) do
                ffi.copy(instance._CDATA + offset, b:cdata(), b:size())
                offset = offset + b:size()
            end
            instance._MANAGED = true
        elseif not arg2 and arg1:size() then
            -- bytes(bytes): allocates a buffer from another one (strict replica, sharing memory)
            local b = arg1
            local start = 1
            local last = arg3 or b:size()
            if start < 1 or last > b:size() then
                os.raise("incorrect bounds(%d-%d)!", start, last)
            end
            instance._SIZE    = last - start + 1
            instance._CDATA   = b:cdata() - 1 + start
            instance._REF     = b -- keep lua ref for GC
            instance._MANAGED = false
        end
    end
    if instance:cdata() == nil then
        os.raise("invalid arguments for bytes(...)!")
    end
    setmetatable(instance, _instance)
    return instance
end

-- get bytes size
function _instance:size()
    return self._SIZE
end

-- get bytes data
function _instance:cdata()
    return self._CDATA
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

-- get a slice of bytes
function _instance:slice(start, last)
    return bytes(self, start, last)
end

-- copy bytes 
function _instance:copy(src)
    if type(src) == 'string' then
        src = bytes(src)
    end
    if src:size() ~= self:size() then
        os.raise("cannot copy bytes, src and dst must have same size(%d->%d)!", src:size(), self:size())
    end
    ffi.copy(self:cdata(), src:cdata(), self:size())
    return self
end

-- clone a new bytes buffer
function _instance:clone()
    local new = bytes(self:size())
    new:copy(self)
    return new
end

-- convert bytes to string
function _instance:str(i, j)
    local offset = i and i - 1 or 0
    return ffi.string(self:cdata() + offset, (j or self:size()) - offset)
end

-- get byte or bytes slice at the given index position
--
-- bytes[1]
-- bytes[{1, 2}]
--
function _instance:__index(key)
    if type(key) == "number" then
        if key < 1 or key > self:size() then 
            os.raise("bytes index(%d/%d) out of bounds!", key, self:size()) 
        end
        return self._CDATA[key - 1]
    elseif type(key) == "table" then
        local start, last = key[1], key[2]
        return self:slice(start, last)
    end
    return rawget(self, key)
end

-- get byte or bytes slice at the given index position
--
-- bytes[1] = 0x1
-- bytes[{1, 2}] = bytes(2)
--
function _instance:__newindex(key, value)
    if type(key) == "number" then
        if key < 1 or key > self:size() then 
            os.raise("bytes index(%d/%d) out of bounds!", key, self:size()) 
        end
        self._CDATA[key - 1] = value
        return
    elseif type(key) == "table" then
        local start, last = key[1], key[2]
        self:slice(start,last):copy(value)
        return
    end
    rawset(self, key, value)
end

-- concat two bytes buffer
function _instance:__concat(other)
    local new = bytes(self:size() + other:size())
    new:slice(1, self:size()):copy(self)
    new:slice(self:size() + 1, new:size()):copy(other)
    return new
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
