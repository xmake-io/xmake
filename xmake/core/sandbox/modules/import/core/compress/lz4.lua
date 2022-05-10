--!A cross-platform build utility compressd on Lua
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

-- define module
local sandbox_core_compress_lz4 = sandbox_core_compress_lz4 or {}

-- load modules
local lz4   = require("compress/lz4")
local raise = require("sandbox/modules/raise")

-- compress frame data
function sandbox_core_compress_lz4.compress(data, opt)
    local result, errors = lz4.compress(data, opt)
    if not result and errors then
        raise(errors)
    end
    return result
end

-- decompress frame data
function sandbox_core_compress_lz4.decompress(data, opt)
    local result, errors = lz4.decompress(data, opt)
    if not result and errors then
        raise(errors)
    end
    return result
end

-- compress file data
function sandbox_core_compress_lz4.compress_file(srcpath, dstpath, opt)
    local result, errors = lz4.compress_file(srcpath, dstpath, opt)
    if not result and errors then
        raise(errors)
    end
end

-- decompress file data
function sandbox_core_compress_lz4.decompress_file(srcpath, dstpath, opt)
    local result, errors = lz4.decompress_file(srcpath, dstpath, opt)
    if not result and errors then
        raise(errors)
    end
end

-- compress block data
function sandbox_core_compress_lz4.block_compress(data, opt)
    local result, errors = lz4.block_compress(data, opt)
    if not result and errors then
        raise(errors)
    end
    return result
end

-- decompress block data
function sandbox_core_compress_lz4.block_decompress(data, realsize, opt)
    local result, errors = lz4.block_decompress(data, realsize, opt)
    if not result and errors then
        raise(errors)
    end
    return result
end

-- new compress stream
function sandbox_core_compress_lz4.compress_stream(opt)
    local result, errors = lz4.compress_stream(opt)
    if not result and errors then
        raise(errors)
    end
    return result
end

-- new a decompress stream
function sandbox_core_compress_lz4.decompress_stream(opt)
    local result, errors = lz4.decompress_stream(opt)
    if not result and errors then
        raise(errors)
    end
    return result
end

-- return module
return sandbox_core_compress_lz4
