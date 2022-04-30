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

-- define module: hash
local hash  = hash or {}

-- load modules
local io    = require("base/io")
local utils = require("base/utils")
local bytes = require("base/bytes")

-- save metatable and builtin functions
hash._sha256  = hash._sha256 or hash.sha256

-- make sha256 from the given file or data
function hash.sha256(file_or_data)
    local hashstr, errors
    if bytes.instance_of(file_or_data) then
        local datasize = file_or_data:size()
        local dataaddr = file_or_data:caddr()
        hashstr, errors = hash._sha256(dataaddr, datasize)
    else
        hashstr, errors = hash._sha256(file_or_data)
    end
    return hashstr, errors
end

-- return module: hash
return hash
