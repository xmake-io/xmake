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
local sandbox_core_compress_lz4_cstream = sandbox_core_compress_lz4_cstream or {}
local sandbox_core_compress_lz4_dstream = sandbox_core_compress_lz4_dstream or {}

-- load modules
local lz4   = require("compress/lz4")
local raise = require("sandbox/modules/raise")

-- wrap compress stream
function _cstream_wrap(instance)
    local hooked = {}
    for name, func in pairs(sandbox_core_compress_lz4_cstream) do
        if not name:startswith("_") and type(func) == "function" then
            hooked["_" .. name] = instance["_" .. name] or instance[name]
            hooked[name] = func
        end
    end
    for name, func in pairs(hooked) do
        instance[name] = func
    end
    return instance
end

-- wrap decompress stream
function _dstream_wrap(instance)
    local hooked = {}
    for name, func in pairs(sandbox_core_compress_lz4_dstream) do
        if not name:startswith("_") and type(func) == "function" then
            hooked["_" .. name] = instance["_" .. name] or instance[name]
            hooked[name] = func
        end
    end
    for name, func in pairs(hooked) do
        instance[name] = func
    end
    return instance
end

-- read data from stream
function sandbox_core_compress_lz4_cstream.read(stream, buff, size, opt)
    local real, data_or_errors = stream:_read(buff, size, opt)
    if real < 0 and data_or_errors then
        raise(data_or_errors)
    end
    return real, data_or_errors
end

-- write data to stream
function sandbox_core_compress_lz4_cstream.write(stream, data, opt)
    local real, errors = stream:_write(data, opt)
    if real < 0 and errors then
        raise(errors)
    end
    return real
end

-- read data from stream
function sandbox_core_compress_lz4_dstream.read(stream, buff, size, opt)
    local real, data_or_errors = stream:_read(buff, size, opt)
    if real < 0 and data_or_errors then
        raise(data_or_errors)
    end
    return real, data_or_errors
end

-- write data to stream
function sandbox_core_compress_lz4_dstream.write(stream, data, opt)
    local real, errors = stream:_write(data, opt)
    if real < 0 and errors then
        raise(errors)
    end
    return real
end

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
    return _cstream_wrap(result)
end

-- new a decompress stream
function sandbox_core_compress_lz4.decompress_stream(opt)
    local result, errors = lz4.decompress_stream(opt)
    if not result and errors then
        raise(errors)
    end
    return _dstream_wrap(result)
end

-- return module
return sandbox_core_compress_lz4
