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
-- @file        bytes.lua
--

-- define module: bytes
local bytes = bytes or {}
local _instance = _instance or {}

-- load modules
local bit        = require('bit')
local ffi        = require('ffi')
local os         = require("base/os")
local utils      = require("base/utils")
local todisplay  = require("base/todisplay")

-- define ffi interfaces
ffi.cdef[[
    void* malloc(size_t size);
    void  free(void* data);
]]

-- new a bytes instance
--
-- bytes(size[, init]): allocates a buffer of given size, init with given number or char value
-- bytes(size, ptr [, manage]): mounts buffer on existing storage (manage memory or not)
-- bytes(str): mounts a buffer from the given string
-- bytes(bytes, start, last): mounts a buffer from another one, with start/last limits
-- bytes(bytes1, bytes2, bytes3, ...): allocates and concat buffer from list of byte buffers
-- bytes(bytes): allocates a buffer from another one (strict replica, sharing memory)
-- bytes({bytes1, bytes2, ...}): allocates and concat buffer from a list of byte buffers (table)
-- bytes({})/bytes(): allocate an empty buffer
--
function _instance.new(...)
    local args = {...}
    local arg1, arg2, arg3 = unpack(args)
    local instance = table.inherit(_instance)
    if type(arg1) == "number" then
        local size = arg1
        if type(arg2) == "cdata" then
            -- bytes(size, ptr [, manage]): mounts buffer on existing storage (manage memory or not)
            local ptr = arg2
            local manage = arg3
            if manage then
                instance._CDATA   = ffi.gc(ffi.cast("unsigned char*", ptr), ffi.C.free)
                instance._MANAGED = true
            else
                instance._CDATA   = ffi.cast("unsigned char*", ptr)
                instance._MANAGED = false
            end
        else
            -- bytes(size[, init]): allocates a buffer of given size
            local init
            if arg2 then
                if type(arg2) == "number" then
                    init = arg2
                elseif type(arg2) == "string" then
                    init = arg2:byte()
                else
                    os.raise("invalid arguments #2 for bytes(size, ...), cdata, string, number or nil expected!")
                end
            end
            local ptr = ffi.C.malloc(size)
            if init then
                ffi.fill(ptr, size, init)
            end
            instance._CDATA   = ffi.gc(ffi.cast("unsigned char*", ptr), ffi.C.free)
            instance._MANAGED = true
        end
        instance._SIZE     = size
        instance._READONLY = false
    elseif type(arg1) == "string" then
        -- bytes(str): mounts a buffer from the given string
        local str = arg1
        instance._SIZE     = #str
        instance._CDATA    = ffi.cast("unsigned char*", str)
        instance._REF      = str -- keep ref for GC
        instance._MANAGED  = false
        instance._READONLY = true
    elseif type(arg1) == "table" then
        if type(arg2) == 'number' then
            -- bytes(bytes, start, last): mounts a buffer from another one, with start/last limits:
            local b = arg1
            local start = arg2 or 1
            local last = arg3 or b:size()
            if start < 1 or last > b:size() then
                os.raise("incorrect bounds(%d-%d) for bytes(...)!", start, last)
            end
            instance._SIZE     = last - start + 1
            instance._CDATA    = b:cdata() - 1 + start
            instance._REF      = b -- keep lua ref for GC
            instance._MANAGED  = false
            instance._READONLY = b:readonly()
        elseif type(arg2) == "table" then
            -- bytes(bytes1, bytes2, bytes3, ...): allocates and concat buffer from list of byte buffers
            instance._SIZE = 0
            for _, b in ipairs(args) do
                instance._SIZE = instance._SIZE + b:size()
            end
            instance._CDATA = ffi.gc(ffi.cast("unsigned char*", ffi.C.malloc(instance._SIZE)), ffi.C.free)
            local offset = 0
            for _, b in ipairs(args) do
                ffi.copy(instance._CDATA + offset, b:cdata(), b:size())
                offset = offset + b:size()
            end
            instance._MANAGED  = true
            instance._READONLY = false
        elseif not arg2 and arg1[1] and type(arg1[1]) == 'table' then
            -- bytes({bytes1, bytes2, ...}): allocates and concat buffer from a list of byte buffers (table)
            args = arg1
            instance._SIZE = 0
            for _, b in ipairs(args) do
                instance._SIZE = instance._SIZE + b:size()
            end
            instance._CDATA = ffi.gc(ffi.cast("unsigned char*", ffi.C.malloc(instance._SIZE)), ffi.C.free)
            local offset = 0
            for _, b in ipairs(args) do
                ffi.copy(instance._CDATA + offset, b._CDATA, b:size())
                offset = offset + b:size()
            end
            instance._MANAGED  = true
            instance._READONLY = false
        elseif not arg2 and arg1.size and arg1:size() > 0 then
            -- bytes(bytes): allocates a buffer from another one (strict replica, sharing memory)
            local b = arg1
            local start = 1
            local last = arg3 or b:size()
            if start < 1 or last > b:size() then
                os.raise("incorrect bounds(%d-%d)!", start, last)
            end
            instance._SIZE     = last - start + 1
            instance._CDATA    = b:cdata() - 1 + start
            instance._REF      = b -- keep lua ref for GC
            instance._MANAGED  = false
            instance._READONLY = b:readonly()
        else
            -- bytes({}): allocate an empty buffer
            instance._SIZE     = 0
            instance._CDATA    = nil
            instance._MANAGED  = false
            instance._READONLY = true
        end
    elseif arg1 == nil then
        -- bytes(): allocate an empty buffer
        instance._SIZE     = 0
        instance._CDATA    = nil
        instance._MANAGED  = false
        instance._READONLY = true
    end
    if instance:size() == nil then
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

-- get data address
function _instance:caddr()
    return tonumber(ffi.cast('unsigned long long', self:cdata()))
end

-- readonly?
function _instance:readonly()
    return self._READONLY
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
    if self:readonly() then
        os.raise("%s: cannot be modified!", self)
    end
    if type(src) == 'string' then
        src = bytes(src)
    end
    if src:size() ~= self:size() then
        os.raise("%s: cannot copy bytes, src and dst must have same size(%d->%d)!", self, src:size(), self:size())
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

-- dump whole bytes data
function _instance:dump()

    local i    = 0
    local n    = 147
    local p    = 0
    local e    = self:size()
    local line = nil
    while p < e do
        line = ""
        if p + 0x20 <= e then

            -- dump offset
            line = line .. string.format("${color.dump.anchor}%08X ${color.dump.number}", p)

            -- dump data
            for i = 0, 0x20 - 1 do
                if (i % 4) == 0 then
                    line = line .. " "
                end
                line = line .. string.format(" %02X", self[p + i + 1])
            end

            -- dump spaces
            line = line .. "  "

            -- dump characters
            line = line .. "${color.dump.string}"
            for i = 0, 0x20 - 1 do
                local v = self[p + i + 1]
                if v > 0x1f and v < 0x7f then
                    line = line .. string.format("%c", v)
                else
                    line = line .. '.'
                end
            end
            line = line .. "${clear}"

            -- dump line
            utils.cprint(line)

            -- next line
            p = p + 0x20

        elseif p < e then

            -- init padding
            local padding = n - 0x20

            -- dump offset
            line = line .. string.format("${color.dump.anchor}%08X ${color.dump.number}", p)
            if padding >= 9 then
                padding = padding - 9
            end

            -- dump data
            local left = e - p
            for i = 0, left - 1 do
                if (i % 4) == 0 then
                    line = line .. " "
                    if padding then
                        padding = padding - 1
                    end
                end
                line = line .. string.format(" %02X", self[p + i + 1])
                if padding >= 3 then
                    padding = padding - 3
                end
            end

            -- dump spaces
            while padding > 0 do
                line = line .. " "
                padding = padding - 1
            end

            -- dump characters
            line = line .. "${color.dump.string}"
            for i = 0, left - 1 do
                local v = self[p + i + 1]
                if v > 0x1f and v < 0x7f then
                    line = line .. string.format("%c", v)
                else
                    line = line .. '.'
                end
            end
            line = line .. "${clear}"

            -- dump line
            utils.cprint(line)

            -- next line
            p = p + left

        else
            break
        end
    end
end

-- convert bytes to string
function _instance:str(i, j)
    local offset = i and i - 1 or 0
    return ffi.string(self:cdata() + offset, (j or self:size()) - offset)
end

-- get uint8 value
function _instance:u8(offset)
    return self[offset]
end

-- get sint8 value
function _instance:s8(offset)
    local value = self[offset]
    return value < 0x80 and value or -0x100 + value
end

-- get uint16 little-endian value
function _instance:u16le(offset)
    return bit.lshift(self[offset + 1], 8) + self[offset]
end

-- get uint16 big-endian value
function _instance:u16be(offset)
    return bit.lshift(self[offset], 8) + self[offset + 1]
end

-- get sint16 little-endian value
function _instance:s16le(offset)
    local value = self:u16le(offset)
    return value < 0x8000 and value or -0x10000 + value
end

-- get sint16 big-endian value
function _instance:s16be(offset)
    local value = self:u16be(offset)
    return value < 0x8000 and value or -0x10000 + value
end

-- get uint32 little-endian value
function _instance:u32le(offset)
    return self[offset + 3] * 0x1000000 + bit.lshift(self[offset + 2], 16) + bit.lshift(self[offset + 1], 8) + self[offset]
end

-- get uint32 big-endian value
function _instance:u32be(offset)
   return self[offset] * 0x1000000 + bit.lshift(self[offset + 1], 16) + bit.lshift(self[offset + 2], 8) + self[offset + 3]
end

-- get sint32 little-endian value
function _instance:s32le(offset)
   return bit.tobit(self:u32le(offset))
end

-- get sint32 big-endian value
function _instance:s32be(offset)
   return bit.tobit(self:u32be(offset))
end

-- get byte or bytes slice at the given index position
--
-- bytes[1]
-- bytes[{1, 2}]
--
function _instance:__index(key)
    if type(key) == "number" then
        if key < 1 or key > self:size() then
            os.raise("%s: index(%d/%d) out of bounds!", self, key, self:size())
        end
        return self._CDATA[key - 1]
    elseif type(key) == "table" then
        local start, last = key[1], key[2]
        return self:slice(start, last)
    end
    return rawget(self, key)
end

-- set byte or bytes slice at the given index position
--
-- bytes[1] = 0x1
-- bytes[{1, 2}] = bytes(2)
--
function _instance:__newindex(key, value)
    if self:readonly() then
        os.raise("%s: cannot modify value at index[%s]!", self, key)
    end
    if type(key) == "number" then
        if key < 1 or key > self:size() then
            os.raise("%s: index(%d/%d) out of bounds!", self, key, self:size())
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
    return "<bytes: " .. self:size() .. ">"
end

-- todisplay(bytes)
function _instance:__todisplay()
    local parts = {}
    local size = self:size()
    if size > 8 then
        size = 8
    end
    for i = 1, size do
        parts[i] = "0x" .. bit.tohex(self[i], 2)
    end
    return "bytes${reset}(" .. todisplay(self:size()) .. ") <${color.dump.number}" .. table.concat(parts, " ") .. (self:size() > 8 and "${reset} ..>" or "${reset}>")
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
    __todisplay = function()
        return todisplay(bytes.new)
    end
})

-- return module: bytes
return bytes
