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
-- @file        socket.lua
--

-- define module
local socket      = socket or {}
local _instance   = _instance or {}

-- load modules
local io     = require("base/io")
local table  = require("base/table")
local string = require("base/string")

-- the socket types
socket.TCP   = 1
socket.UDP   = 2
socket.ICMP  = 3

-- the socket families
socket.IPV4  = 1
socket.IPV6  = 2

-- the socket events
socket.EV_RECV = 1
socket.EV_SEND = 2
socket.EV_CONN = socket.EV_SEND
socket.EV_ACPT = socket.EV_RECV

-- new a socket
function _instance.new(socktype, family, sock)
    local instance   = table.inherit(_instance)
    instance._SOCK   = sock
    instance._TYPE   = socktype 
    instance._FAMILY = family
    setmetatable(instance, _instance)
    return instance
end

-- get socket type
function _instance:type()
    return self._TYPE
end

-- get socket family
function _instance:family()
    return self._FAMILY
end

-- get socket rawfd
function _instance:rawfd()

    -- ensure opened
    local ok, errors = self:_ensure_opened()
    if not ok then
        return nil, errors
    end

    -- get rawfd
    local result, errors = io.socket_rawfd(self._SOCK)
    if not result and errors then
        errors = string.format("%s: %s", self, errors)
    end
    return result, errors
end

-- connect socket 
function _instance:connect(addr, port)

    -- ensure opened
    local ok, errors = self:_ensure_opened()
    if not ok then
        return -1, errors
    end

    -- connect it
    local result, errors = io.socket_connect(self._SOCK, addr, port, self:family())
    if result < 0 and errors then
        errors = string.format("%s: %s", self, errors)
    end
    return result, errors
end

-- wait socket events
function _instance:wait(events, timeout)

    -- ensure opened
    local ok, errors = self:_ensure_opened()
    if not ok then
        return -1, errors
    end

    -- wait it
    local result, errors = io.socket_wait(self._SOCK, events, timeout or -1)
    if result < 0 and errors then
        errors = string.format("%s: %s", self, errors)
    end
    return result, errors
end

-- close socket
function _instance:close()

    -- ensure opened
    local ok, errors = self:_ensure_opened()
    if not ok then
        return false, errors
    end

    -- close it
    ok = io.socket_close(self._SOCK)
    if ok then
        self._SOCK = nil
    end
    return ok
end

-- ensure the socket is opened
function _instance:_ensure_opened()
    if not self._SOCK then
        return false, string.format("%s: has been closed!", self)
    end
    return true
end

-- tostring(socket)
function _instance:__tostring()
    local rawfd = self:rawfd() or "closed"
    local types = {"tcp", "udp", "icmp"}
    return string.format("<socket: %s%s/%s>", types[self:type()], self:family() == socket.IPV6 and "6" or "4", rawfd)
end

-- gc(socket)
function _instance:__gc()
    if self._SOCK and io.socket_close(self._SOCK) then
        self._SOCK = nil
    end
end

-- open a socket
--
-- @param socktype      the socket type, e.g. tcp, udp, icmp
-- @param family        the address family, e.g. ipv4, ipv6
--
-- @return the socket instance
--
function socket.open(socktype, family)
    socktype = socktype or socket.TCP
    family   = family or socket.IPV4
    local sock, errors = io.socket_open(socktype, family)
    if sock then
        return _instance.new(socktype, family, sock)
    else
        return nil, errors or string.format("failed to open socket(%s/%s)!", socktype, family)
    end
end

-- return module
return socket
