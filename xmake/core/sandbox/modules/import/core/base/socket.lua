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

-- load modules
local utils     = require("base/utils")
local socket    = require("base/socket")
local string    = require("base/string")
local raise     = require("sandbox/modules/raise")

-- define module
local sandbox_core_base_socket            = sandbox_core_base_socket or {}
local sandbox_core_base_socket_instance   = sandbox_core_base_socket_instance or {}

-- connect socket 
function sandbox_core_base_socket_instance.connect(sock, addr, port)
    local result, errors = sock:_connect(addr, port)
    if result < 0 and errors then
        raise(errors)
    end
    return result
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

    -- open sock
    local sock, errors = socket.open(socktype, family)
    if not sock then
        raise(errors)
    end

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

-- open tcp/ipv4 socket
function sandbox_core_base_socket.open_tcp4()
    return sandbox_core_base_socket.open("tcp", "ipv4")
end

-- open tcp/ipv6 socket
function sandbox_core_base_socket.open_tcp6()
    return sandbox_core_base_socket.open("tcp", "ipv6")
end

-- open udp/ipv4 socket
function sandbox_core_base_socket.open_udp4()
    return sandbox_core_base_socket.open("udp", "ipv4")
end

-- open udp/ipv6 socket
function sandbox_core_base_socket.open_udp6()
    return sandbox_core_base_socket.open("udp", "ipv6")
end

-- return module
return sandbox_core_base_socket

