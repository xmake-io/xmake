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
lz4._compress_file    = lz4._compress_file or lz4.compress_file
lz4._decompress_file  = lz4._decompress_file or lz4.decompress_file

-- compress frame data
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
        return nil, errors or string.format("compress frame data failed, %s", errors or "unknown")
    end
    return bytes(result)
end

-- decompres frame data
--
-- @param data          the data
-- @param opt           the options
--
-- @return              the result data
--
function lz4.decompress(data, opt)
    if type(data) == "string" then
        data = bytes(data)
    end
    local datasize = data:size()
    local dataaddr = data:caddr()
    local result, errors = lz4._decompress(dataaddr, datasize)
    if not result then
        return nil, string.format("decompress frame data failed, %s", errors or "unknown")
    end
    return bytes(result)
end

-- compress file data
function lz4.compress_file(srcpath, dstpath, opt)
    local ok, errors = lz4._compress_file(tostring(srcpath), tostring(dstpath))
    if not ok then
        errors = string.format("compress file %s failed!", srcpath, errors or os.strerror() or "unknown")
    end
    return ok, errors
end

-- decompress file data
function lz4.decompress_file(srcpath, dstpath, opt)
    local ok, errors = lz4._decompress_file(tostring(srcpath), tostring(dstpath))
    if not ok then
        errors = string.format("compress file %s failed!", srcpath, errors or os.strerror() or "unknown")
    end
    return ok, errors
end

-- compress block data
--
-- @param data          the data
-- @param opt           the options
--
-- @return              the result data
--
function lz4.block_compress(data, opt)
    if type(data) == "string" then
        data = bytes(data)
    end
    local datasize = data:size()
    local dataaddr = data:caddr()
    local result, errors = lz4._block_compress(dataaddr, datasize)
    if not result then
        return nil, errors or string.format("compress block data failed, %s", errors or "unknown")
    end
    return bytes(result)
end

-- decompres block data
--
-- @param data          the data
-- @param realsize      the decompressed real size
-- @param opt           the options
--
-- @return              the result data
--
function lz4.block_decompress(data, realsize, opt)
    local datasize = data:size()
    local dataaddr = data:caddr()
    local result, errors = lz4._block_decompress(dataaddr, datasize, realsize)
    if not result then
        return nil, string.format("decompress block data failed, %s", errors or "unknown")
    end
    return bytes(result)
end

-- return module: lz4
return lz4
