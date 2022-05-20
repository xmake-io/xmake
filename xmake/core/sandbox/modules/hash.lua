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
-- @file        hash.lua
--

-- load modules
local hash  = require("base/hash")
local raise = require("sandbox/modules/raise")

-- define module
local sandbox_hash = sandbox_hash or {}

-- make a new uuid
function sandbox_hash.uuid(name)
    return sandbox_hash.uuid4(name)
end

-- make a new uuid v4
function sandbox_hash.uuid4(name)
    local uuid = hash.uuid4(name)
    if not uuid then
        raise("cannot make uuid %s", name)
    end
    return uuid
end

-- make sha1 from the given file or data
function sandbox_hash.sha1(file_or_data)
    local sha1, errors = hash.sha1(file_or_data)
    if not sha1 then
        raise("cannot make sha1 for %s, %s", file_or_data, errors or "unknown errors")
    end
    return sha1
end

-- make sha256 from the given file or data
function sandbox_hash.sha256(file_or_data)
    local sha256, errors = hash.sha256(file_or_data)
    if not sha256 then
        raise("cannot make sha256 for %s, %s", file_or_data, errors or "unknown errors")
    end
    return sha256
end

-- make md5 from the given file or data
function sandbox_hash.md5(file_or_data)
    local md5, errors = hash.md5(file_or_data)
    if not md5 then
        raise("cannot make md5 for %s, %s", file_or_data, errors or "unknown errors")
    end
    return md5
end

-- make xxhash64 from the given file or data
function sandbox_hash.xxhash64(file_or_data)
    local xxhash64, errors = hash.xxhash64(file_or_data)
    if not xxhash64 then
        raise("cannot make xxhash64 for %s, %s", file_or_data, errors or "unknown errors")
    end
    return xxhash64
end

-- make xxhash128 from the given file or data
function sandbox_hash.xxhash128(file_or_data)
    local xxhash128, errors = hash.xxhash128(file_or_data)
    if not xxhash128 then
        raise("cannot make xxhash128 for %s, %s", file_or_data, errors or "unknown errors")
    end
    return xxhash128
end

-- return module
return sandbox_hash

