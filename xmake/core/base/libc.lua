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
-- @file        libc.lua
--

-- define module: libc
local libc = libc or {}

-- save original interfaces
libc._malloc  = libc._malloc or libc.malloc
libc._free    = libc._free or libc.free
libc._memcpy  = libc._memcpy or libc.memcpy
libc._memmov  = libc._memmov or libc.memmov
libc._memset  = libc._memset or libc.memset
libc._strndup = libc._strndup or libc.strndup
libc._dataptr = libc._dataptr or libc.dataptr
libc._byteof  = libc._byteof or libc.byteof
libc._setbyte = libc._setbyte or libc.setbyte

-- load modules
local ffi = xmake._LUAJIT and require("ffi")

-- define ffi interfaces
if ffi then
    ffi.cdef[[
        void* malloc(size_t size);
        void  free(void* data);
        void* memmove(void* dest, const void* src, size_t n);
    ]]
end

function libc.malloc(size, opt)
    if ffi then
        if opt and opt.gc then
            return ffi.gc(ffi.cast("unsigned char*", ffi.C.malloc(size)), ffi.C.free)
        else
            return ffi.cast("unsigned char*", ffi.C.malloc(size))
        end
    else
        local data, errors = libc._malloc(size)
        if not data then
            os.raise(errors)
        end
        return data
    end
end

function libc.free(data)
    if ffi then
        return ffi.C.free(data)
    else
        return libc._free(data)
    end
end

function libc.memcpy(dst, src, size)
    if ffi then
        return ffi.copy(dst, src, size)
    else
        return libc._memcpy(dst, src, size)
    end
end

function libc.memmov(dst, src, size)
    if ffi then
        return ffi.C.memmove(dst, src, size)
    else
        return libc._memmov(dst, src, size)
    end
end

function libc.memset(data, ch, size)
    if ffi then
        return ffi.fill(data, size, ch)
    else
        libc._memset(data, ch, size)
    end
end

function libc.strndup(s, n)
    if ffi then
        return ffi.string(s, n)
    else
        local s, errors = libc._strndup(s, n)
        if not s then
            os.raise(errors)
        end
        return s
    end
end

function libc.byteof(data, offset)
    if ffi then
        return data[offset]
    else
        return libc._byteof(data, offset)
    end
end

function libc.setbyte(data, offset, value)
    if ffi then
        data[offset] = value
    else
        return libc._setbyte(data, offset, value)
    end
end

function libc.dataptr(data, opt)
    if ffi then
        if opt and opt.gc then
            return ffi.gc(ffi.cast("unsigned char*", data), ffi.C.free)
        else
            return ffi.cast("unsigned char*", data)
        end
    else
        return type(data) == "number" and data or libc._dataptr(data)
    end
end

function libc.ptraddr(data)
    if ffi then
        return tonumber(ffi.cast('unsigned long long', data))
    else
        return data
    end
end

-- return module: libc
return libc
