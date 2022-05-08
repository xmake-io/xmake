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
-- @file        lz4.lua
--

-- define module: lz4
local lz4  = lz4 or {}

-- load modules
local io    = require("base/io")
local utils = require("base/utils")
local bytes = require("base/bytes")

-- save metatable and builtin functions
lz4._compress         = lz4._compress or lz4.compress
lz4._decompress       = lz4._decompress or lz4.decompress
lz4._block_compress   = lz4._block_compress or lz4.block_compress
lz4._block_decompress = lz4._block_decompress or lz4.block_decompress

-- compress data
--
-- @param data          the data
-- @param opt           the options
--
-- @return              the result data
--
function lz4.compress(data, opt)
    if type(data) == "string" then
        data = bytes(data)
    end
    local datasize = data:size()
    local dataaddr = data:caddr()
    local result, errors = lz4._compress(dataaddr, datasize)
    if not result then
        return nil, errors or string.format("compress lz4 data failed, %s", errors or "unknown")
    end
    return bytes(result)
end

-- decompres data
--
-- @param data          the data
-- @param opt           the options
--
-- @return              the result data
--
function lz4.decompress(data, opt)
    local datasize = data:size()
    local dataaddr = data:caddr()
    local result, errors = lz4._decompress(dataaddr, datasize)
    if not result then
        return nil, string.format("decompress lz4 data failed, %s", errors or "unknown")
    end
    return bytes(result)
end

-- return module: lz4
return lz4
