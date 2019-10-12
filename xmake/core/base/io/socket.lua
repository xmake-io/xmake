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
local io        = io or {}
local _socket   = _socket or {}

-- load modules
local table  = require("base/table")
local string = require("base/string")

-- new a socket
function _socket.new(socktype, family, sock)
    local socket   = table.inherit(_socket)
    socket._SOCK   = sock
    socket._TYPE   = socktype
    socket._FAMILY = family
    setmetatable(socket, _socket)
    return socket
end

-- get socket type
function _socket:type()
    return self._TYPE
end

-- get socket family
function _socket:family()
    return self._FAMILY
end

-- close socket
function _socket:close()

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
function _socket:_ensure_opened()
    if not self._SOCK then
        return false, string.format("%s: has been closed!", self)
    end
    return true
end

-- tostring(socket)
function _socket:__tostring()
    return string.format("<socket: %s/%s>", self:type(), self:family())
end

-- gc(socket)
function _socket:__gc()
    if self._SOCK and io.socket_close(self._SOCK) then
        self._SOCK = nil
    end
end

-- open a socket
function io.opensock(socktype, family)
    local sock = io.socket_open(socktype, family)
    if sock then
        return _socket.new(socktype, family, sock)
    else
        return nil, string.format("failed to open socket!")
    end
end
