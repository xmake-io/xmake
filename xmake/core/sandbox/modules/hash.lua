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

-- load modules
local hash  = require("base/hash")
local raise = require("sandbox/modules/raise")

-- define module
local sandbox_hash = sandbox_hash or {}

-- generate a new uuid
function sandbox_hash.uuid(str)
    local uuid = hash.uuid(str)
    if not uuid then
        raise("cannot generate uuid %s", str)
    end
    return uuid
end

-- generate a new uuid v4
function sandbox_hash.uuid4(str)
    local uuid = hash.uuid4(str)
    if not uuid then
        raise("cannot generate uuid4 %s", str)
    end
    return uuid
end

-- generate sha1 from the given file or data
function sandbox_hash.sha1(file_or_data)
    local sha1, errors = hash.sha1(file_or_data)
    if not sha1 then
        raise("cannot generate sha1, %s", errors or "unknown errors")
    end
    return sha1
end

-- generate sha256 from the given file or data
function sandbox_hash.sha256(file_or_data)
    local sha256, errors = hash.sha256(file_or_data)
    if not sha256 then
        raise("cannot generate sha256, %s", errors or "unknown errors")
    end
    return sha256
end

-- generate md5 from the given file or data
function sandbox_hash.md5(file_or_data)
    local md5, errors = hash.md5(file_or_data)
    if not md5 then
        raise("cannot generate md5, %s", errors or "unknown errors")
    end
    return md5
end

-- generate xxhash32 from the given file or data
function sandbox_hash.xxhash32(file_or_data)
    local result, errors = hash.xxhash32(file_or_data)
    if not result then
        raise("cannot generate xxhash32, %s", errors or "unknown errors")
    end
    return result
end

-- generate xxhash64 from the given file or data
function sandbox_hash.xxhash64(file_or_data)
    local result, errors = hash.xxhash64(file_or_data)
    if not result then
        raise("cannot generate xxhash64, %s", errors or "unknown errors")
    end
    return result
end

-- generate xxhash128 from the given file or data
function sandbox_hash.xxhash128(file_or_data)
    local result, errors = hash.xxhash128(file_or_data)
    if not result then
        raise("cannot generate xxhash128, %s", errors or "unknown errors")
    end
    return result
end

-- generate hash32 from string
function sandbox_hash.strhash32(str)
    local result, errors = hash.strhash32(str)
    if not result then
        raise("cannot generate hash32 for %s, %s", str, errors or "unknown errors")
    end
    return result
end

-- generate hash64 from string
function sandbox_hash.strhash64(str)
    local result, errors = hash.strhash64(str)
    if not result then
        raise("cannot generate hash32 for %s, %s", str, errors or "unknown errors")
    end
    return result
end

-- generate hash128 from string
function sandbox_hash.strhash128(str)
    local result, errors = hash.strhash128(str)
    if not result then
        raise("cannot generate hash128 for %s, %s", str, errors or "unknown errors")
    end
    return result
end

-- generate random32
function sandbox_hash.random32()
    local result, errors = hash.random32()
    if not result then
        raise("cannot generate random32, %s", errors or "unknown errors")
    end
    return result
end

-- generate random64
function sandbox_hash.random64()
    local result, errors = hash.random64()
    if not result then
        raise("cannot generate random64, %s", errors or "unknown errors")
    end
    return result
end

-- generate random128
function sandbox_hash.random128()
    local result, errors = hash.random128()
    if not result then
        raise("cannot generate random128, %s", errors or "unknown errors")
    end
    return result
end

-- return module
return sandbox_hash

