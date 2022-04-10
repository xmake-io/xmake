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
-- @file        socket_stream.lua
--

-- imports
import("core.base.object")
import("core.base.socket")
import("core.base.bytes")
import("private.service.message")

-- define module
local socket_stream = socket_stream or object()

-- init socket_stream
function socket_stream:init(sock)
    self._SOCK = sock
    self._BUFF = bytes(65536)
    self._RCACHE = bytes(8192)
    self._RCACHE_SIZE = 0
    self._WCACHE = bytes(8192)
    self._WCACHE_SIZE = 0
end

-- get socket
function socket_stream:sock()
    return self._SOCK
end

-- flush data
function socket_stream:flush()
    local cache = self._WCACHE
    local cache_size = self._WCACHE_SIZE
    if cache_size > 0 then
        local sock = self._SOCK
        local real = sock:send(cache, {block = true, last = cache_size})
        if real > 0 then
            self._WCACHE_SIZE = 0
            return true
        end
    else
        return true
    end
end

-- send the given bytes
function socket_stream:send(data, start, last)
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
    local real = sock:send(cache, {block = true})
    if real > 0 then
        -- copy left data to cache
        assert(size <= cache_maxn)
        cache:copy2(1, data, start, last)
        self._WCACHE_SIZE = size
        return true
    end
end

-- send message
function socket_stream:send_msg(msg)
    return self:send_object(msg:body())
end

-- send object
function socket_stream:send_object(obj)
    local str, errors = string.serialize(obj, {strip = true, indent = false})
    if errors then
        raise(errors)
    end
    if str then
        return self:send_string(str)
    end
end

-- send string
function socket_stream:send_string(str)
    local buff = self._BUFF
    local size = #str
    buff:u16be_set(1, size)
    if self:send(buff, 1, 2) then
        return self:send(bytes(str), 1, size)
    end
end

-- recv the given bytes
function socket_stream:recv(buff, size)
    assert(size <= buff:size())

    -- read data from cache first
    local buffsize = 0
    local cache = self._RCACHE
    local cache_size = self._RCACHE_SIZE
    local cache_maxn = cache:size()
    if size <= cache_size then
        buff:copy(cache, 1, size)
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
            if sock:wait(socket.EV_RECV, -1) == socket.EV_RECV then
                wait = true
            else
                break
            end
        else
            break
        end
    end
end

-- recv u16be
function socket_stream:recv_u16be()
    local data = self:recv(self._BUFF, 2)
    if data then
        return data:u16be(1)
    end
end

-- recv message
function socket_stream:recv_msg()
    local body = self:recv_object()
    if body then
        return message(body)
    end
end

-- recv object
function socket_stream:recv_object()
    local str = self:recv_string()
    if str then
        local obj, errors = str:deserialize()
        if errors then
            raise(errors)
        end
        return obj
    end
end

-- recv string
function socket_stream:recv_string()
    local size = self:recv_u16be()
    if size then
        local data = self:recv(self._BUFF, size)
        if data then
            return data:str()
        end
    end
end

function main(sock)
    local instance = socket_stream()
    instance:init(sock)
    return instance
end
