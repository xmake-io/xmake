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
-- @file        hash.lua
--

-- load modules
local raise = require("sandbox/modules/raise")

-- define module
local sandbox_hash = sandbox_hash or {}

-- make a new uuid
function sandbox_hash.uuid(name)

    -- make it
    local uuid = hash.uuid(name)
    if not uuid then
        raise("cannot make uuid %s", name)
    end

    -- ok?
    return uuid
end

-- make sha256 from the given file
function sandbox_hash.sha256(file)

    -- make it
    local sha256 = hash.sha256(file)
    if not sha256 then
        raise("cannot make sha256 for %s", file)
    end

    -- ok?
    return sha256
end

-- return module
return sandbox_hash

