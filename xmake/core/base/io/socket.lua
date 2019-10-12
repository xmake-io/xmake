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
function _socket.new(sock)
    local socket = table.inherit(_socket)
    socket._SOCK = sock
    socket._NAME = ""
    setmetatable(socket, _socket)
    return socket
end

-- get the socket name 
function _socket:name()
    return self._NAME
end

-- close socket
function _socket:close()
    if not self._SOCK then
        return false, string.format("socket(%s) has been closed!", self:name())
    end
    local ok = io.socket_close(self._SOCK)
    if ok then
        self._SOCK = nil
    end
    return ok
end

-- tostring(socket)
function _socket:__tostring()
    return "socket: " .. self:name()
end

-- gc(socket)
function _socket:__gc()
    if self._SOCK and io.socket_close(self._SOCK) then
        self._SOCK = nil
    end
end

-- open a socket
function io.opensock()

    -- open it
    local sock = io.socket_open()
    if sock then
        return _socket.new(filepath, sock)
    else
        return nil, string.format("failed to open socket!")
    end
end
