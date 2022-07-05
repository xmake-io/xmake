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
-- @file        stream.lua
--

-- imports
import("core.base.bit")
import("core.base.object")
import("core.base.socket")
import("core.base.bytes")
import("core.compress.lz4")
import("private.service.message")

-- define module
local stream = stream or object()

-- max data buffer size
local STREAM_DATA_MAXN = 10 * 1024 * 1024

-- the header flags
local HEADER_FLAG_COMPRESS_LZ4 = 1

-- init stream
function stream:init(sock, opt)
    opt = opt or {}
    self._SOCK = sock
    self._BUFF = bytes(65536)
    self._RCACHE = bytes(8192)
    self._RCACHE_SIZE = 0
    self._WCACHE = bytes(8192)
    self._WCACHE_SIZE = 0
    self._SEND_TIMEOUT = opt.send_timeout and opt.send_timeout or -1
    self._RECV_TIMEOUT = opt.recv_timeout and opt.recv_timeout or -1
end

-- get socket
function stream:sock()
    return self._SOCK
end

-- get send timeout
function stream:send_timeout()
    return self._SEND_TIMEOUT
end

-- get send timeout
function stream:recv_timeout()
    return self._RECV_TIMEOUT
end

-- flush data
function stream:flush(opt)
    opt = opt or {}
    local cache = self._WCACHE
    local cache_size = self._WCACHE_SIZE
    if cache_size > 0 then
        local sock = self._SOCK
        local real = sock:send(cache, {block = true, last = cache_size, timeout = opt.timeout or self:send_timeout()})
        if real > 0 then
            self._WCACHE_SIZE = 0
            return true
        end
    else
        return true
    end
end

-- send the given bytes (small data)
function stream:send(data, start, last, opt)
    opt = opt or {}
    start = start or 1
    last = last or data:size()
    local size = last + 1 - start
    assert(size <= data:size())

    -- write data to cache first
    local cache = self._WCACHE
    local cache_size = self._WCACHE_SIZE
    local cache_maxn = cache:size()
    local cache_left = cache_maxn - cache_size
    if size <= cache_left then
        cache:copy2(cache_size + 1, data, start, last)
        cache_size = cache_size + size
        self._WCACHE_SIZE = cache_size
        return true
    elseif cache_left > 0 then
        cache:copy2(cache_size + 1, data, start, start + cache_left - 1)
        cache_size = cache_size + cache_left
        start = start + cache_left
        size = last + 1 - start
    end
    assert(cache_size == cache_maxn)

    -- send data to socket
    local sock = self._SOCK
    local real = sock:send(cache, {block = true, timeout = opt.timeout or self:send_timeout()})
    if real > 0 then
        -- copy left data to cache
        assert(size <= cache_maxn)
        cache:copy2(1, data, start, last)
        self._WCACHE_SIZE = size
        return true
    end
end

-- send message
function stream:send_msg(msg, opt)
    return self:send_object(msg:body(), opt)
end

-- send object
function stream:send_object(obj, opt)
    local str, errors = string.serialize(obj, {strip = true, indent = false})
    if errors then
        raise(errors)
    end
    if str then
        return self:send_string(str, opt)
    end
end

-- send data header
function stream:send_header(size, flags, opt)
    local buff = self._BUFF
    buff:u32be_set(1, size)
    buff:u8_set(5, flags or 0)
    return self:send(buff, 1, 5, opt)
end

-- send data
function stream:send_data(data, opt)
    opt = opt or {}
    local flags = 0
    if opt.compress then
        flags = bit.bor(flags, HEADER_FLAG_COMPRESS_LZ4)
        data = lz4.compress(data)
    end
    local size = data:size()
    assert(size < STREAM_DATA_MAXN, "too large data size(%d)", size)
    if self:send_header(size, flags, opt) then
        local send = 0
        local cache = self._WCACHE
        local cache_maxn = cache:size()
        while send < size do
            local left = math.min(cache_maxn, size - send)
            if self:send(data, send + 1, send + left, opt) then
                send = send + left
            else
                break
            end
        end
        if send == size then
            return true
        end
    end
end

-- send string
function stream:send_string(str, opt)
    return self:send_data(bytes(str), opt)
end

-- send empty data
function stream:send_emptydata(opt)
    return self:send_header(0, opt)
end

-- send file
function stream:send_file(filepath, opt)

    -- send header
    opt = opt or {}
    local flags = 0
    local tmpfile
    local originsize = os.filesize(filepath)
    if opt.compress and originsize > 0 then
        flags = bit.bor(flags, HEADER_FLAG_COMPRESS_LZ4)
        tmpfile = os.tmpfile()
        lz4.compress_file(filepath, tmpfile)
        filepath = tmpfile
    end

    -- send header
    local size = os.filesize(filepath)
    if not self:send_header(size, flags) then
        return
    end

    -- empty file?
    if size == 0 then
        return 0, 0
    end

    -- flush cache data first
    if not self:flush() then
        return
    end

    -- send file
    local ok = false
    local sock = self._SOCK
    local file = io.open(filepath, 'rb')
    if file then
        local send = sock:sendfile(file, {block = true, timeout = opt.timeout or self:send_timeout()})
        if send > 0 then
            ok = true
        end
        file:close()
    end
    if tmpfile then
        os.tryrm(tmpfile)
    end
    if ok then
        return originsize, size
    end
end

-- send files
function stream:send_files(filepaths, opt)
    local size
    local compressed_size
    for _, filepath in ipairs(filepaths) do
        local real, compressed_real = self:send_file(filepath, opt)
        if real then
            size = (size or 0) + real
            compressed_size = (compressed_size or 0) + compressed_real
        else
            return
        end
    end
    return size, compressed_size
end

-- recv the given bytes
function stream:recv(buff, size, opt)
    opt = opt or {}
    assert(size <= buff:size(), "too large size(%d)", size)

    -- read data from cache first
    local buffsize = 0
    local cache = self._RCACHE
    local cache_size = self._RCACHE_SIZE
    local cache_maxn = cache:size()
    if size <= cache_size then
        buff:copy(cache, 1, size)
        cache:move(size + 1, cache_size)
        cache_size = cache_size - size
        self._RCACHE_SIZE = cache_size
        return buff:slice(1, size)
    elseif cache_size > 0 then
        buff:copy(cache, 1, cache_size)
        buffsize = cache_size
        cache_size = 0
    end
    assert(cache_size == 0)

    -- recv data from socket
    local real = 0
    local data = nil
    local wait = false
    local sock = self._SOCK
    while buffsize < size do
        real, data = sock:recv(cache)
        if real > 0 then
            -- append data to buffer
            local leftsize = size - buffsize
            if real < leftsize then
                buff:copy2(buffsize + 1, data)
                buffsize = buffsize + real
            else
                buff:copy2(buffsize + 1, data, 1, leftsize)
                buffsize = buffsize + leftsize

                -- move left cache to head
                cache_size = real - leftsize
                if cache_size > 0 then
                    cache:move(leftsize + 1, real)
                end
                self._RCACHE_SIZE = cache_size
                return buff:slice(1, buffsize)
            end
            wait = false
        elseif real == 0 and not wait then
            local ok = sock:wait(socket.EV_RECV, opt.timeout or self:recv_timeout())
            if ok == socket.EV_RECV then
                wait = true
            else
                assert(ok ~= 0, "%s: recv timeout!", self)
                break
            end
        else
            break
        end
    end
end

-- recv message
function stream:recv_msg(opt)
    local body = self:recv_object(opt)
    if body then
        return message(body)
    end
end

-- recv object
function stream:recv_object(opt)
    local str = self:recv_string(opt)
    if str then
        local obj, errors = str:deserialize()
        if errors then
            raise(errors)
        end
        return obj
    end
end

-- recv header
function stream:recv_header(opt)
    local data = self:recv(self._BUFF, 5, opt)
    if data then
        local size = data:u32be(1)
        local flags = data:u8(5)
        return size, flags
    end
end

-- recv data
function stream:recv_data(opt)
    local size, flags = self:recv_header(opt)
    if size then
        local recv = 0
        assert(size < STREAM_DATA_MAXN, "too large data size(%d)", size)
        local buff = bytes(size)
        while recv < size do
            local data = self:recv(buff:slice(recv + 1), size - recv, opt)
            if data then
                recv = recv + data:size()
            else
                break
            end
        end
        if recv == size then
            if bit.band(flags, HEADER_FLAG_COMPRESS_LZ4) == HEADER_FLAG_COMPRESS_LZ4 then
                buff = lz4.decompress(buff)
            end
            return buff
        end
    end
end

-- recv string
function stream:recv_string(opt)
    local data = self:recv_data(opt)
    if data then
        return data:str()
    end
end

-- recv file
function stream:recv_file(filepath, opt)
    local size, flags = self:recv_header(opt)
    if size then
        -- empty file? we just create an empty file
        if size == 0 then
            local file = io.open(filepath, "wb")
            file:close()
            return size
        end
        local result
        local tmpfile = os.tmpfile({ramdisk = false})
        if bit.band(flags, HEADER_FLAG_COMPRESS_LZ4) == HEADER_FLAG_COMPRESS_LZ4 then
            result = self:_recv_compressed_file(lz4.decompress_stream(), tmpfile, size, opt)
        else
            local buff = self._BUFF
            local recv = 0
            local file = io.open(tmpfile, "wb")
            while recv < size do
                local data = self:recv(buff, math.min(buff:size(), size - recv), opt)
                if data then
                    file:write(data)
                    recv = recv + data:size()
                end
            end
            file:close()
            if recv == size then
                result = recv
            end
        end
        if result then
            os.cp(tmpfile, filepath)
        end
        os.tryrm(tmpfile)
        return result
    end
end

-- recv files
function stream:recv_files(filepaths, opt)
    local size, decompressed_size
    for _, filepath in ipairs(filepaths) do
        local real, decompressed_real = self:recv_file(filepath, opt)
        if real then
            size = (size or 0) + real
            decompressed_size = (decompressed_size or 0) + decompressed_real
        else
            return
        end
    end
    return size, decompressed_size
end

-- recv compressed file
function stream:_recv_compressed_file(lz4_stream, filepath, size, opt)
    local buff = self._BUFF
    local recv = 0
    local file = io.open(filepath, "wb")
    local decompressed_size = 0
    while recv < size do
        local data = self:recv(buff, math.min(buff:size(), size - recv), opt)
        if data then
            local write = 0
            local writesize = data:size()
            while write < writesize do
                local blocksize = math.min(writesize - write, 8192)
                local real = lz4_stream:write(data, {start = write + 1, last = write + blocksize})
                if real > 0 then
                    while true do
                        local decompressed_real, decompressed_data = lz4_stream:read(buff, 8192)
                        if decompressed_real > 0 and decompressed_data then
                            file:write(decompressed_data)
                            decompressed_size = decompressed_size + decompressed_real
                        else
                            break
                        end
                    end
                end
                write = write + blocksize
            end
            recv = recv + data:size()
        end
    end
    file:close()
    if recv == size then
        return recv, decompressed_size
    end
end

function stream:__tostring()
    return string.format("<stream: %s>", self:sock())
end

function main(sock, opt)
    local instance = stream()
    instance:init(sock, opt)
    return instance
end
