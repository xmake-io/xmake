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
local lz4 = lz4 or {}
local _cstream = _cstream or {}
local _dstream = _dstream or {}

-- load modules
local io    = require("base/io")
local utils = require("base/utils")
local bytes = require("base/bytes")
local table = require("base/table")

-- save metatable and builtin functions
lz4._compress                = lz4._compress or lz4.compress
lz4._decompress              = lz4._decompress or lz4.decompress
lz4._block_compress          = lz4._block_compress or lz4.block_compress
lz4._block_decompress        = lz4._block_decompress or lz4.block_decompress
lz4._compress_file           = lz4._compress_file or lz4.compress_file
lz4._decompress_file         = lz4._decompress_file or lz4.decompress_file
lz4._compress_stream_open    = lz4._compress_stream_open or lz4.compress_stream_open
lz4._compress_stream_read    = lz4._compress_stream_read or lz4.compress_stream_read
lz4._compress_stream_write   = lz4._compress_stream_write or lz4.compress_stream_write
lz4._compress_stream_close   = lz4._compress_stream_close or lz4.compress_stream_close
lz4._decompress_stream_open  = lz4._decompress_stream_open or lz4.decompress_stream_open
lz4._decompress_stream_read  = lz4._decompress_stream_read or lz4.decompress_stream_read
lz4._decompress_stream_write = lz4._decompress_stream_write or lz4.decompress_stream_write
lz4._decompress_stream_close = lz4._decompress_stream_close or lz4.decompress_stream_close

-- new a compress stream
function _cstream.new(handle)
    local instance   = table.inherit(_cstream)
    instance._HANDLE = handle
    setmetatable(instance, _cstream)
    return instance
end

-- get cdata of stream
function _cstream:cdata()
    return self._HANDLE
end

-- read data from stream
function _cstream:read(buff, size, opt)
    assert(buff)

    -- ensure opened
    local ok, errors = self:_ensure_opened()
    if not ok then
        return -1, errors
    end

    -- check buffer
    size = size or buff:size()
    if buff:size() < size then
        return -1, string.format("%s: too small buffer!", self)
    end

    -- check size
    if size == 0 then
        return 0
    elseif size == nil or size < 0 then
        return -1, string.format("%s: invalid size(%d)!", self, size)
    end

    -- init start in buffer
    opt = opt or {}
    local start = opt.start or 1
    local pos = start - 1
    if start >= buff:size() or start < 1 then
        return -1, string.format("%s: invalid start(%d)!", self, start)
    end

    -- read it
    local read, data_or_errors = lz4._compress_stream_read(self:cdata(), buff:caddr() + pos, math.min(buff:size() - pos, size))
    if read > 0 then
        data_or_errors = buff:slice(start, read)
    end
    if read < 0 and data_or_errors then
        data_or_errors = string.format("%s: %s", self, data_or_errors)
    end
    return read, data_or_errors
end

-- write data to stream
function _cstream:write(data, opt)

    -- ensure opened
    local ok, errors = self:_ensure_opened()
    if not ok then
        return -1, errors
    end

    -- get data address and size for bytes and string
    if type(data) == "string" then
        data = bytes(data)
    end
    local datasize = data:size()
    local dataaddr = data:caddr()

    -- init start and last
    opt = opt or {}
    local start = opt.start or 1
    local last = opt.last or datasize
    if start < 1 or start > datasize then
        return -1, string.format("%s: invalid start(%d)!", self, start)
    end
    if last < start - 1 or last > datasize + start - 1 then
        return -1, string.format("%s: invalid last(%d)!", self, last)
    end

    -- write it
    local errors = nil
    local write, errors = lz4._compress_stream_write(self:cdata(), dataaddr + start - 1, last + 1 - start, opt.beof)
    if write < 0 and errors then
        errors = string.format("%s: %s", self, errors)
    end
    return write, errors
end

-- ensure it is opened
function _cstream:_ensure_opened()
    if not self:cdata() then
        return false, string.format("%s: has been closed!", self)
    end
    return true
end

-- tostring(stream)
function _cstream:__tostring()
    return string.format("<lz4/cstream: %s>", self:cdata())
end

-- gc(stream)
function _cstream:__gc()
    if self:cdata() and lz4._compress_stream_close(self:cdata()) then
        self._HANDLE = nil
    end
end

-- new a decompress stream
function _dstream.new(handle)
    local instance   = table.inherit(_dstream)
    instance._HANDLE = handle
    setmetatable(instance, _dstream)
    return instance
end

-- get cdata of stream
function _dstream:cdata()
    return self._HANDLE
end

-- read data from stream
function _dstream:read(buff, size, opt)
    assert(buff)

    -- ensure opened
    local ok, errors = self:_ensure_opened()
    if not ok then
        return -1, errors
    end

    -- check buffer
    size = size or buff:size()
    if buff:size() < size then
        return -1, string.format("%s: too small buffer!", self)
    end

    -- check size
    if size == 0 then
        return 0
    elseif size == nil or size < 0 then
        return -1, string.format("%s: invalid size(%d)!", self, size)
    end

    -- init start in buffer
    opt = opt or {}
    local start = opt.start or 1
    local pos = start - 1
    if start >= buff:size() or start < 1 then
        return -1, string.format("%s: invalid start(%d)!", self, start)
    end

    -- read it
    local read, data_or_errors = lz4._decompress_stream_read(self:cdata(), buff:caddr() + pos, math.min(buff:size() - pos, size))
    if read > 0 then
        data_or_errors = buff:slice(start, read)
    end
    if read < 0 and data_or_errors then
        data_or_errors = string.format("%s: %s", self, data_or_errors)
    end
    return read, data_or_errors
end

-- write data to stream
function _dstream:write(data, opt)

    -- ensure opened
    local ok, errors = self:_ensure_opened()
    if not ok then
        return -1, errors
    end

    -- get data address and size for bytes and string
    if type(data) == "string" then
        data = bytes(data)
    end
    local datasize = data:size()
    local dataaddr = data:caddr()

    -- init start and last
    opt = opt or {}
    local start = opt.start or 1
    local last = opt.last or datasize
    if start < 1 or start > datasize then
        return -1, string.format("%s: invalid start(%d)!", self, start)
    end
    if last < start - 1 or last > datasize + start - 1 then
        return -1, string.format("%s: invalid last(%d)!", self, last)
    end

    -- write it
    local errors = nil
    local write, errors = lz4._decompress_stream_write(self:cdata(), dataaddr + start - 1, last + 1 - start, opt.beof)
    if write < 0 and errors then
        errors = string.format("%s: %s", self, errors)
    end
    return write, errors
end

-- ensure it is opened
function _dstream:_ensure_opened()
    if not self:cdata() then
        return false, string.format("%s: has been closed!", self)
    end
    return true
end

-- tostring(stream)
function _dstream:__tostring()
    return string.format("<lz4/dstream: %s>", self:cdata())
end

-- gc(stream)
function _dstream:__gc()
    if self:cdata() and lz4._decompress_stream_close(self:cdata()) then
        self._HANDLE = nil
    end
end

-- open a compress stream
function lz4.compress_stream(opt)
    local handle, errors = lz4._compress_stream_open()
    if handle then
        return _cstream.new(handle)
    else
        return nil, errors or "failed to open compress stream!"
    end
end

-- open a decompress stream
function lz4.decompress_stream(opt)
    local handle, errors = lz4._decompress_stream_open()
    if handle then
        return _dstream.new(handle)
    else
        return nil, errors or "failed to open decompress stream!"
    end
end

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
        errors = string.format("decompress file %s failed!", srcpath, errors or os.strerror() or "unknown")
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
