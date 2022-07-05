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
-- @file        socket.lua
--

-- define module
local socket      = socket or {}
local _instance   = _instance or {}

-- load modules
local io        = require("base/io")
local libc      = require("base/libc")
local bytes     = require("base/bytes")
local table     = require("base/table")
local string    = require("base/string")
local scheduler = require("base/scheduler")

-- the socket types
socket.TCP   = 1
socket.UDP   = 2
socket.ICMP  = 3

-- the socket families
socket.IPV4  = 1
socket.IPV6  = 2
socket.UNIX  = 3

-- the socket events, @see tbox/platform/socket.h
socket.EV_RECV = 1
socket.EV_SEND = 2
socket.EV_CONN = socket.EV_SEND
socket.EV_ACPT = socket.EV_RECV

-- the socket control code
socket.CTRL_SET_RECVBUFF = 2
socket.CTRL_SET_SENDBUFF = 4

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

-- get cdata of socket
function _instance:cdata()
    return self._SOCK
end

-- get poller object type, poller.OT_SOCK
function _instance:otype()
    return 1
end

-- get socket rawfd
function _instance:rawfd()

    -- ensure opened
    local ok, errors = self:_ensure_opened()
    if not ok then
        return nil, errors
    end

    -- get rawfd
    local result, errors = io.socket_rawfd(self:cdata())
    if not result and errors then
        errors = string.format("%s: %s", self, errors)
    end
    return result, errors
end

-- get socket peer address
function _instance:peeraddr()

    -- ensure opened
    local ok, errors = self:_ensure_opened()
    if not ok then
        return nil, errors
    end

    -- get peer address
    local result, errors = io.socket_peeraddr(self:cdata())
    if not result and errors then
        errors = string.format("%s: %s", self, errors)
    end
    return result, errors
end

-- control socket
function _instance:ctrl(code, value)

    -- ensure opened
    local ok, errors = self:_ensure_opened()
    if not ok then
        return -1, errors
    end

    -- control it
    local ok, errors = io.socket_ctrl(self:cdata(), code, value)
    if not ok and errors then
        errors = string.format("%s: %s", self, errors)
    end
    return ok, errors
end

-- bind socket
function _instance:bind(addr, port)

    -- ensure opened
    local ok, errors = self:_ensure_opened()
    if not ok then
        return -1, errors
    end

    -- bind it
    local ok, errors = io.socket_bind(self:cdata(), addr, port, self:family())
    if not ok and errors then
        errors = string.format("%s: %s", self, errors)
    end
    return ok, errors
end

-- bind socket from the unix address
function _instance:bind_unix(addr, opt)

    -- ensure opened
    local ok, errors = self:_ensure_opened()
    if not ok then
        return -1, errors
    end

    -- must be unix socket
    if self:family() ~= socket.UNIX then
        return -1, string.format("%s: must be unix socket!", self)
    end

    -- bind it
    opt = opt or {}
    local ok, errors = io.socket_bind(self:cdata(), addr, opt.is_abstract, self:family())
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
    local ok, errors = io.socket_listen(self:cdata(), backlog or 10)
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
    local sock, errors = io.socket_accept(self:cdata())
    if not sock and not errors then
        opt = opt or {}
        local events, waiterrs = _instance.wait(self, socket.EV_ACPT, opt.timeout or -1)
        if events == socket.EV_ACPT then
            sock, errors = io.socket_accept(self:cdata())
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
    local ok, errors = io.socket_connect(self:cdata(), addr, port, self:family())
    if ok == 0 then
        opt = opt or {}
        local events, waiterrs = _instance.wait(self, socket.EV_CONN, opt.timeout or -1)
        if events == socket.EV_CONN then
            ok, errors = io.socket_connect(self:cdata(), addr, port, self:family())
        else
            errors = waiterrs
        end
    end
    if ok < 0 and errors then
        errors = string.format("%s: %s", self, errors)
    end
    return ok, errors
end

-- connect socket from the unix address
function _instance:connect_unix(addr, opt)

    -- ensure opened
    local ok, errors = self:_ensure_opened()
    if not ok then
        return -1, errors
    end

    -- must be unix socket
    if self:family() ~= socket.UNIX then
        return -1, string.format("%s: must be unix socket!", self)
    end

    -- connect it
    opt = opt or {}
    local ok, errors = io.socket_connect(self:cdata(), addr, opt.is_abstract, self:family())
    if ok == 0 then
        local events, waiterrs = _instance.wait(self, socket.EV_CONN, opt.timeout or -1)
        if events == socket.EV_CONN then
            ok, errors = io.socket_connect(self:cdata(), addr, opt.is_abstract, self:family())
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

    -- send it
    local send = 0
    local real = 0
    local wait = false
    local errors = nil
    if opt.block then
        local size = last + 1 - start
        while start <= last do
            real, errors = io.socket_send(self:cdata(), dataaddr + start - 1, last + 1 - start)
            if real > 0 then
                send = send + real
                start = start + real
                wait = false
            elseif real == 0 and not wait then
                local events, waiterrs = _instance.wait(self, socket.EV_SEND, opt.timeout or -1)
                if events == socket.EV_SEND then
                    wait = true
                elseif events == 0 then
                    os.raise("%s: send timeout!", self)
                else
                    errors = waiterrs
                    break
                end
            else
                break
            end
        end
        if send ~= size then
            send = -1
        end
    else
        send, errors = io.socket_send(self:cdata(), dataaddr + start - 1, last + 1 - start)
        if send < 0 and errors then
            errors = string.format("%s: %s", self, errors)
        end
    end
    return send, errors
end

-- send file to socket
function _instance:sendfile(file, opt)

    -- ensure the socket opened
    local ok, errors = self:_ensure_opened()
    if not ok then
        return -1, errors
    end

    -- ensure the file opened
    local ok, errors = file:_ensure_opened()
    if not ok then
        return -1, errors
    end

    -- empty file?
    if file:size() == 0 then
        return -1, string.format("%s: send empty file!", self)
    end

    -- init start and last
    opt = opt or {}
    local start = opt.start or 1
    local last = opt.last or file:size()

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
        local size = last + 1 - start
        while start <= last do
            real, errors = io.socket_sendfile(self:cdata(), file._FILE, start, last)
            if real > 0 then
                send = send + real
                start = start + real
                wait = false
            elseif real == 0 and not wait then
                local events, waiterrs = _instance.wait(self, socket.EV_SEND, opt.timeout or -1)
                if events == socket.EV_SEND then
                    wait = true
                elseif events == 0 then
                    os.raise("%s: sendfile timeout!", self)
                else
                    errors = waiterrs
                    break
                end
            else
                break
            end
        end
        if send ~= size then
            send = -1
        end
    else
        send, errors = io.socket_sendfile(self:cdata(), file._FILE, start, last)
        if send < 0 and errors then
            errors = string.format("%s: %s", self, errors)
        end
    end
    return send, errors
end

-- recv data from socket
function _instance:recv(buff, size, opt)
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

    -- recv it
    local recv = 0
    local real = 0
    local wait = false
    local data_or_errors = nil
    if opt.block then
        while recv < size do
            real, data_or_errors = io.socket_recv(self:cdata(), buff:caddr() + pos + recv, math.min(buff:size() - pos - recv, size - recv))
            if real > 0 then
                recv = recv + real
                wait = false
            elseif real == 0 and not wait then
                local events, waiterrs = _instance.wait(self, socket.EV_RECV, opt.timeout or -1)
                if events == socket.EV_RECV then
                    wait = true
                elseif events == 0 then
                    os.raise("%s: recv timeout!", self)
                else
                    data_or_errors = waiterrs
                    break
                end
            else
                break
            end
        end
        if recv == size then
            data_or_errors = buff:slice(start, recv)
        else
            recv = -1
        end
    else
        recv, data_or_errors = io.socket_recv(self:cdata(), buff:caddr() + pos, math.min(buff:size() - pos, size))
        if recv > 0 then
            data_or_errors = buff:slice(start, recv)
        end
    end
    if recv < 0 and data_or_errors then
        data_or_errors = string.format("%s: %s", self, data_or_errors)
    end
    return recv, data_or_errors
end

-- send udp data to peer
function _instance:sendto(data, addr, port, opt)

    -- ensure opened
    local ok, errors = self:_ensure_opened()
    if not ok then
        return -1, errors
    end

    -- only for udp
    if self:type() ~= socket.UDP then
        return -1, string.format("%s: sendto() only for udp socket!", self)
    end

    -- check address
    if not addr or not port then
        return -1, string.format("%s: sendto empty address!", self)
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

    -- send it
    local send = 0
    local wait = false
    local errors = nil
    if opt.block then
        while true do
            send, errors = io.socket_sendto(self:cdata(), dataaddr + start - 1, last + 1 - start, addr, port, self:family())
            if send == 0 and not wait then
                local events, waiterrs = _instance.wait(self, socket.EV_SEND, opt.timeout or -1)
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
        send, errors = io.socket_sendto(self:cdata(), dataaddr + start - 1, last + 1 - start, addr, port, self:family())
        if send < 0 and errors then
            errors = string.format("%s: %s", self, errors)
        end
    end
    return send, errors
end

-- recv udp data from peer
function _instance:recvfrom(buff, size, opt)
    assert(buff)

    -- ensure opened
    local ok, errors = self:_ensure_opened()
    if not ok then
        return -1, errors
    end

    -- only for udp
    if self:type() ~= socket.UDP then
        return -1, string.format("%s: sendto() only for udp socket!", self)
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

    -- recv it
    local recv = 0
    local wait = false
    local data_or_errors = nil
    if opt.block then
        while true do
            recv, data_or_errors, addr, port = io.socket_recvfrom(self:cdata(), buff:caddr() + pos, math.min(buff:size() - pos, size))
            if recv > 0 then
                data_or_errors = buff:slice(start, recv)
                break
            elseif recv == 0 and not wait then
                local events, waiterrs = _instance.wait(self, socket.EV_RECV, opt.timeout or -1)
                if events == socket.EV_RECV then
                    wait = true
                else
                    recv = -1
                    data_or_errors = waiterrs
                    break
                end
            else
                break
            end
        end
    else
        recv, data_or_errors, addr, port = io.socket_recvfrom(self:cdata(), buff:caddr() + pos, math.min(buff:size() - pos, size))
        if recv > 0 then
            data_or_errors = buff:slice(start, recv)
        end
    end
    if recv < 0 and data_or_errors then
        data_or_errors = string.format("%s: %s", self, data_or_errors)
    end
    return recv, data_or_errors, addr, port
end

-- wait socket events
function _instance:wait(events, timeout)

    -- ensure opened
    local ok, errors = self:_ensure_opened()
    if not ok then
        return -1, errors
    end

    -- wait events
    local result = -1
    local errors = nil
    if scheduler:co_running() then
        result, errors = scheduler:poller_wait(self, events, timeout or -1)
    else
        result, errors = io.socket_wait(self:cdata(), events, timeout or -1)
    end
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

    -- cancel socket events from the scheduler
    if scheduler:co_running() then
        ok, errors = scheduler:poller_cancel(self)
        if not ok then
            return false, errors
        end
    end

    -- close it
    ok = io.socket_close(self:cdata())
    if ok then
        self._SOCK = nil
    end
    return ok
end

-- ensure the socket is opened
function _instance:_ensure_opened()
    if not self:cdata() then
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
    if self:cdata() and io.socket_close(self:cdata()) then
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

-- open unix socket
function socket.unix(opt)
    return socket.open(socket.TCP, socket.UNIX)
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
        return nil, string.format("bind %s:%s failed, %s!", addr, port, errors or "unknown reason")
    end
    return sock
end

-- open and bind tcp socket from the unix address
function socket.bind_unix(addr, opt)
    local sock, errors = socket.unix(opt)
    if not sock then
        return nil, errors
    end
    local ok, errors = sock:bind_unix(addr, opt)
    if not ok then
        sock:close()
        return nil, string.format("bind unix://%s failed, %s!", addr, errors or "unknown reason")
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
        return nil, errors
    end
    return sock
end

-- open and connect tcp socket from the unix address
function socket.connect_unix(addr, opt)
    local sock, errors = socket.unix(opt)
    if not sock then
        return nil, errors
    end
    local ok, errors = sock:connect_unix(addr, opt)
    if ok <= 0 then
        sock:close()
        return nil, errors
    end
    return sock
end

-- return module
return socket
