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

-- bind socket 
function _instance:bind(addr, port)

    -- ensure opened
    local ok, errors = self:_ensure_opened()
    if not ok then
        return -1, errors
    end

    -- bind it
    local ok, errors = io.socket_bind(self._SOCK, addr, port, self:family())
    if not ok and errors then
        errors = string.format("%s: %s", self, errors)
    end
    return ok, errors
end

-- listen socket 
function _instance:listen(backlog)

    -- ensure opened
    local ok, errors = self:_ensure_opened()
    if not ok then
        return -1, errors
    end

    -- listen it
    local ok, errors = io.socket_listen(self._SOCK, backlog or 10)
    if not ok and errors then
        errors = string.format("%s: %s", self, errors)
    end
    return ok, errors
end

-- accept socket 
function _instance:accept(opt)

    -- ensure opened
    local ok, errors = self:_ensure_opened()
    if not ok then
        return -1, errors
    end

    -- accept it
    local sock, errors = io.socket_accept(self._SOCK)
    if not sock and not errors then
        opt = opt or {}
        local events, waiterrs = self:wait(socket.EV_ACPT, opt.timeout or -1)
        if events == socket.EV_ACPT then
            sock, errors = io.socket_accept(self._SOCK)
        else
            errors = waiterrs
        end
    end
    if not sock and errors then
        errors = string.format("%s: %s", self, errors)
    end
    if sock then
        sock = _instance.new(self:type(), self:family(), sock)
    end
    return sock, errors
end

-- connect socket 
function _instance:connect(addr, port, opt)

    -- ensure opened
    local ok, errors = self:_ensure_opened()
    if not ok then
        return -1, errors
    end

    -- connect it
    local ok, errors = io.socket_connect(self._SOCK, addr, port, self:family())
    if ok == 0 then
        opt = opt or {}
        local events, waiterrs = self:wait(socket.EV_CONN, opt.timeout or -1)
        if events == socket.EV_CONN then
            ok, errors = io.socket_connect(self._SOCK, addr, port, self:family())
        else
            errors = waiterrs
        end
    end
    if ok < 0 and errors then
        errors = string.format("%s: %s", self, errors)
    end
    return ok, errors
end

-- send data to socket 
function _instance:send(data, opt)

    -- ensure opened
    local ok, errors = self:_ensure_opened()
    if not ok then
        return -1, errors
    end

    -- init start and last
    opt = opt or {}
    local start = opt.start or 1
    local last = opt.last or #data

    -- check start and last
    if start > last or start < 1 then
        return -1, string.format("%s: invalid start(%d) and last(%d)!", self, start, last)
    end

    -- send it
    local send = 0
    local real = 0
    local wait = false
    local errors = nil
    if opt.block then
        while start < last do
            real, errors = io.socket_send(self._SOCK, data, start, last)
            if real > 0 then
                send = send + real
                start = start + real
                wait = false
            elseif real == 0 and not wait then
                local events, waiterrs = self:wait(socket.EV_SEND, opt.timeout or -1)
                if events == socket.EV_SEND then
                    wait = true
                else
                    errors = waiterrs
                    break
                end
            else
                break
            end
        end
    else
        send, errors = io.socket_send(self._SOCK, data, start, last)
        if send < 0 and errors then
            errors = string.format("%s: %s", self, errors)
        end
    end
    return send, errors
end

-- recv data from socket 
function _instance:recv(size, opt)

    -- ensure opened
    local ok, errors = self:_ensure_opened()
    if not ok then
        return -1, errors
    end

    -- check size
    if size == 0 then
        return 0
    elseif size == nil or size < 0 then
        return -1, string.format("%s: invalid size(%d)!", self, size)
    end

    -- recv it
    opt = opt or {}
    local recv = 0
    local real = 0
    local wait = false
    local data_or_errors = opt.prevdata
    if opt.block then
        while recv < size do
            real, data_or_errors = io.socket_recv(self._SOCK, size - recv, data_or_errors)
            if real > 0 then
                recv = recv + real
                wait = false
            elseif real == 0 and not wait then
                local events, waiterrs = self:wait(socket.EV_RECV, opt.timeout or -1)
                if events == socket.EV_RECV then
                    wait = true
                else
                    data_or_errors = waiterrs
                    break
                end
            else
                break
            end
        end
    else
        recv, data_or_errors = io.socket_recv(self._SOCK, size)
        if recv < 0 and data_or_errors then
            data_or_errors = string.format("%s: %s", self, data_or_errors)
        end
    end
    return recv, data_or_errors
end

-- wait socket events
function _instance:wait(events, timeout)

    -- ensure opened
    local ok, errors = self:_ensure_opened()
    if not ok then
        return -1, errors
    end

    -- wait it
    local events, errors = io.socket_wait(self._SOCK, events, timeout or -1)
    if events < 0 and errors then
        errors = string.format("%s: %s", self, errors)
    end
    return events, errors
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

-- open tcp socket
function socket.tcp(opt)
    opt = opt or {}
    return socket.open(socket.TCP, opt.family or socket.IPV4)
end

-- open udp socket
function socket.udp(opt)
    opt = opt or {}
    return socket.open(socket.UDP, opt.family or socket.IPV4)
end

-- open and bind tcp socket
function socket.bind(addr, port, opt)
    local sock, errors = socket.tcp(opt)
    if not sock then
        return nil, errors
    end
    local ok, errors = sock:bind(addr, port)
    if not ok then
        sock:close()
        return nil, string.format("bind %s:%s failed, errors: %s!", addr, port, errors or "")
    end
    return sock
end

-- open and connect tcp socket
function socket.connect(addr, port, opt)
    local sock, errors = socket.tcp(opt)
    if not sock then
        return nil, errors
    end
    local ok, errors = sock:connect(addr, port, opt)
    if ok <= 0 then
        sock:close()
        return nil, string.format("connect %s:%s failed, errors: %s!", addr, port, errors or "")
    end
    return sock
end

-- return module
return socket
