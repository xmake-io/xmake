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
-- Copyright (C) 2015-2020, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        socket.lua
--

-- load modules
local utils     = require("base/utils")
local socket    = require("base/socket")
local string    = require("base/string")
local raise     = require("sandbox/modules/raise")

-- define module
local sandbox_core_base_socket            = sandbox_core_base_socket or {}
local sandbox_core_base_socket_instance   = sandbox_core_base_socket_instance or {}

-- export the socket types
sandbox_core_base_socket.TCP     = socket.TCP
sandbox_core_base_socket.UDP     = socket.UDP
sandbox_core_base_socket.ICMP    = socket.ICMP

-- export the socket families
sandbox_core_base_socket.IPV4    = socket.IPV4
sandbox_core_base_socket.IPV6    = socket.IPV6

-- export the socket events
sandbox_core_base_socket.EV_RECV = socket.EV_RECV
sandbox_core_base_socket.EV_SEND = socket.EV_SEND
sandbox_core_base_socket.EV_CONN = socket.EV_CONN
sandbox_core_base_socket.EV_ACPT = socket.EV_ACPT

-- wrap socket
function _socket_wrap(sock)

    -- hook socket interfaces
    local hooked = {}
    for name, func in pairs(sandbox_core_base_socket_instance) do
        if not name:startswith("_") and type(func) == "function" then
            hooked["_" .. name] = sock["_" .. name] or sock[name]
            hooked[name] = func
        end
    end
    for name, func in pairs(hooked) do
        sock[name] = func
    end
    return sock
end

-- wait socket events
function sandbox_core_base_socket_instance.wait(sock, events, timeout)
    local events, errors = sock:_wait(events, timeout)
    if events < 0 and errors then
        raise(errors)
    end
    return events
end

-- bind socket
function sandbox_core_base_socket_instance.bind(sock, addr, port)
    local ok, errors = sock:_bind(addr, port)
    if not ok and errors then
        raise(errors)
    end
    return ok
end

-- listen socket
function sandbox_core_base_socket_instance.listen(sock, backlog)
    local ok, errors = sock:_listen(backlog)
    if not ok and errors then
        raise(errors)
    end
    return ok
end

-- accept socket
function sandbox_core_base_socket_instance.accept(sock, opt)
    local client_sock, errors = sock:_accept(opt)
    if not client_sock and errors then
        raise(errors)
    end
    return client_sock and _socket_wrap(client_sock) or nil
end

-- connect socket
function sandbox_core_base_socket_instance.connect(sock, addr, port, opt)
    local ok, errors = sock:_connect(addr, port, opt)
    if ok < 0 and errors then
        raise(errors)
    end
    return ok
end

-- send data to socket
function sandbox_core_base_socket_instance.send(sock, data, opt)
    local real, errors = sock:_send(data, opt)
    if real < 0 and errors then
        raise(errors)
    end
    return real
end

-- send file to socket
function sandbox_core_base_socket_instance.sendfile(sock, file, opt)
    local real, errors = sock:_sendfile(file, opt)
    if real < 0 and errors then
        raise(errors)
    end
    return real
end

-- recv data from socket
function sandbox_core_base_socket_instance.recv(sock, size, opt)
    local real, data_or_errors = sock:_recv(size, opt)
    if real < 0 and data_or_errors then
        raise(data_or_errors)
    end
    return real, data_or_errors
end

-- send udp data to peer
function sandbox_core_base_socket_instance.sendto(sock, data, addr, port, opt)
    local real, errors = sock:_sendto(data, addr, port, opt)
    if real < 0 and errors then
        raise(errors)
    end
    return real
end

-- recv udp data from peer
function sandbox_core_base_socket_instance.recvfrom(sock, size, opt)
    local real, data_or_errors, addr, port = sock:_recvfrom(size, opt)
    if real < 0 and data_or_errors then
        raise(data_or_errors)
    end
    return real, data_or_errors, addr, port
end

-- get socket rawfd
function sandbox_core_base_socket_instance.rawfd(sock)
    local result, errors = sock:_rawfd()
    if not result then
        raise(errors)
    end
    return result
end

-- close socket
function sandbox_core_base_socket_instance.close(sock)
    local ok, errors = sock:_close()
    if not ok then
        raise(errors)
    end
end

-- open socket
function sandbox_core_base_socket.open(socktype, family)
    local sock, errors = socket.open(socktype, family)
    if not sock then
        raise(errors)
    end
    return _socket_wrap(sock)
end

-- open tcp socket
function sandbox_core_base_socket.tcp(opt)
    local sock, errors = socket.tcp(opt)
    if not sock then
        raise(errors)
    end
    return _socket_wrap(sock)
end

-- open udp socket
function sandbox_core_base_socket.udp(opt)
    local sock, errors = socket.udp(opt)
    if not sock then
        raise(errors)
    end
    return _socket_wrap(sock)
end

-- open unix socket
function sandbox_core_base_socket.unix(opt)
    local sock, errors = socket.unix(opt)
    if not sock then
        raise(errors)
    end
    return _socket_wrap(sock)
end

-- open and bind tcp socket
function sandbox_core_base_socket.bind(addr, port, opt)
    local sock, errors = socket.bind(addr, port, opt)
    if not sock then
        raise(errors)
    end
    return _socket_wrap(sock)
end

-- open and bind tcp socket from the unix socket
function sandbox_core_base_socket.bind_unix(addr, opt)
    local sock, errors = socket.bind_unix(addr, opt)
    if not sock then
        raise(errors)
    end
    return _socket_wrap(sock)
end

-- open and connect tcp socket
function sandbox_core_base_socket.connect(addr, port, opt)
    local sock, errors = socket.connect(addr, port, opt)
    if not sock and errors then
        raise(errors)
    end
    return sock and _socket_wrap(sock) or nil
end

-- open and connect tcp socket from the unix socket
function sandbox_core_base_socket.connect_unix(addr, opt)
    local sock, errors = socket.connect_unix(addr, opt)
    if not sock and errors then
        raise(errors)
    end
    return sock and _socket_wrap(sock) or nil
end

-- return module
return sandbox_core_base_socket

