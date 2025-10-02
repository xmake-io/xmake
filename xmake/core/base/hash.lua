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
-- @author      ruki
-- @file        hash.lua
--

-- define module: hash
local hash  = hash or {}

-- load modules
local io    = require("base/io")
local utils = require("base/utils")
local bytes = require("base/bytes")
local libc  = require("base/libc")

-- save metatable and builtin functions
hash._md5 = hash._md5 or hash.md5
hash._sha = hash._sha or hash.sha
hash._xxhash = hash._xxhash or hash.xxhash
hash._rand32 = hash._rand32 or hash.rand32
hash._rand64 = hash._rand64 or hash.rand64
hash._rand128 = hash._rand128 or hash.rand128

-- generate md5 from the given file or data
function hash.md5(file_or_data)
    local hashstr, errors
    if bytes.instance_of(file_or_data) then
        local datasize = file_or_data:size()
        local dataaddr = file_or_data:caddr()
        hashstr, errors = hash._md5(dataaddr, datasize)
    else
        hashstr, errors = hash._md5(file_or_data)
    end
    return hashstr, errors
end

-- generate sha1 from the given file or data
function hash.sha1(file_or_data)
    local hashstr, errors
    if bytes.instance_of(file_or_data) then
        local datasize = file_or_data:size()
        local dataaddr = file_or_data:caddr()
        hashstr, errors = hash._sha(160, dataaddr, datasize)
    else
        hashstr, errors = hash._sha(160, file_or_data)
    end
    return hashstr, errors
end

-- generate sha256 from the given file or data
function hash.sha256(file_or_data)
    local hashstr, errors
    if bytes.instance_of(file_or_data) then
        local datasize = file_or_data:size()
        local dataaddr = file_or_data:caddr()
        hashstr, errors = hash._sha(256, dataaddr, datasize)
    else
        hashstr, errors = hash._sha(256, file_or_data)
    end
    return hashstr, errors
end

-- generate uuid, e.g "91E8ECF1-417F-4EDF-A574-E22D7D8D204A"
function hash.uuid(str)
    return hash.uuid4(str)
end

-- generate xxhash32 from the given file or data
function hash.xxhash32(file_or_data)
    local hashstr, errors
    if bytes.instance_of(file_or_data) then
        local datasize = file_or_data:size()
        local dataaddr = file_or_data:caddr()
        hashstr, errors = hash._xxhash(32, dataaddr, datasize)
    else
        hashstr, errors = hash._xxhash(32, file_or_data)
    end
    return hashstr, errors
end

-- generate xxhash64 from the given file or data
function hash.xxhash64(file_or_data)
    local hashstr, errors
    if bytes.instance_of(file_or_data) then
        local datasize = file_or_data:size()
        local dataaddr = file_or_data:caddr()
        hashstr, errors = hash._xxhash(64, dataaddr, datasize)
    else
        hashstr, errors = hash._xxhash(64, file_or_data)
    end
    return hashstr, errors
end

-- generate xxhash128 from the given file or data
function hash.xxhash128(file_or_data)
    local hashstr, errors
    if bytes.instance_of(file_or_data) then
        local datasize = file_or_data:size()
        local dataaddr = file_or_data:caddr()
        hashstr, errors = hash._xxhash(128, dataaddr, datasize)
    else
        hashstr, errors = hash._xxhash(128, file_or_data)
    end
    return hashstr, errors
end

-- generate hash32 from string, e.g. "91e8ecf1"
function hash.strhash32(str)
    local data = libc.ptraddr(libc.dataptr(str))
    local size = #str
    return hash._xxhash(32, data, size)
end

-- generate hash64 from string, e.g. "91e8ecf191e8ecf1"
function hash.strhash64(str)
    local data = libc.ptraddr(libc.dataptr(str))
    local size = #str
    return hash._xxhash(64, data, size)
end

-- generate hash128 from string, e.g. "91e8ecf1417f4edfa574e22d7d8d204a"
function hash.strhash128(str)
    local data = libc.ptraddr(libc.dataptr(str))
    local size = #str
    return hash._xxhash(128, data, size)
end

-- generate random32 hash
function hash.rand32()
    if hash._rand32 then
        return hash._rand32()
    else
        return hash.strhash32(tostring(math.random()))
    end
end

-- generate random64 hash
function hash.rand64()
    if hash._rand64 then
        return hash._rand64()
    else
        return hash.strhash64(tostring(math.random()))
    end
end

-- generate random128 hash
function hash.rand128()
    if hash._rand128 then
        return hash._rand128()
    else
        return hash.strhash128(tostring(math.random()))
    end
end

-- return module: hash
return hash
