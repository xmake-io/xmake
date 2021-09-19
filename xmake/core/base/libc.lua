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
libc._malloc = libc._malloc or libc.malloc

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

-- return module: libc
return libc
