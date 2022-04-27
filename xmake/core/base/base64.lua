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
-- @file        base64.lua
--

-- define module: base64
local base64  = base64 or {}

-- load modules
local io    = require("base/io")
local utils = require("base/utils")
local bytes = require("base/bytes")

-- save metatable and builtin functions
base64._encode  = base64._encode or base64.encode
base64._decode  = base64._decode or base64.decode

-- decode base64 string to the data
--
-- @param base64str       the base64 string
--
-- @return              the data
--
function base64.decode(base64str)
    local data = base64._decode(base64str)
    if not data then
        return nil, string.format("decode base64 failed")
    end
    return bytes(data)
end

-- encode data to the base64 string
--
-- @param data          the data
--
-- @return              the base64 string
--
function base64.encode(data)
    if type(data) == "string" then
        data = bytes(data)
    end
    local datasize = data:size()
    local dataaddr = data:caddr()
    local base64str, errors = base64._encode(dataaddr, datasize)
    if not base64str then
        return nil, errors or string.format("encode base64 failed")
    end
    return base64str
end

-- return module: base64
return base64
