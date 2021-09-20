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
libc._memset  = libc._memset or libc.memset
libc._dataptr = libc._dataptr or libc.dataptr
libc._ptraddr = libc._ptraddr or libc.ptraddr

-- load modules
local ffi = xmake._LUAJIT and require("ffi")

-- define ffi interfaces
if ffi then
    ffi.cdef[[
        void* malloc(size_t size);
        void  free(void* data);
    ]]
end

function libc.malloc(size)
    if ffi then
        return ffi.cast("unsigned char*", ffi.C.malloc(size))
    else
        return libc._malloc(size)
    end
end

function libc.gcmalloc(size)
    if ffi then
        return ffi.gc(ffi.cast("unsigned char*", ffi.C.malloc(size)), ffi.C.free)
    else
        -- @note we need free it in lua/__gc manually
        return libc._malloc(size)
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

function libc.memset(data, ch, size)
    if ffi then
        return ffi.fill(data, size, ch)
    else
        return libc._memset(data, ch, size)
    end
end

function libc.dataptr(data)
    if ffi then
        return ffi.cast("unsigned char*", data)
    else
        return libc._dataptr(data)
    end
end

function libc.ptraddr(data)
    if ffi then
        return tonumber(ffi.cast('unsigned long long', data))
    else
        return libc._ptraddr(data)
    end
end

-- return module: libc
return libc
