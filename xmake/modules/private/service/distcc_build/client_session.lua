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
-- @file        client_session.lua
--

-- imports
import("core.base.pipe")
import("core.base.bytes")
import("core.base.object")
import("core.base.global")
import("core.base.option")
import("core.base.hashset")
import("core.base.scheduler")
import("private.service.client_config", {alias = "config"})
import("private.service.message")
import("private.service.stream", {alias = "socket_stream"})

-- define module
local client_session = client_session or object()

-- init client session
function client_session:init(client, session_id, sock)
    self._ID = session_id
    self._STREAM = socket_stream(sock)
    self._CLIENT = client
end

-- get client session id
function client_session:id()
    return self._ID
end

-- get client
function client_session:client()
    return self._CLIENT
end

-- get stream
function client_session:stream()
    return self._STREAM
end

-- run compilation job
function client_session:iorunv(program, argv, opt)
    opt = opt or {}
    local toolname = opt.toolname
    local iorunv = assert(self["_" .. toolname .. "_iorunv"], "%s: iorunv(%s) is not supported!", self, program)
    return iorunv(self, program, argv, opt)
end

-- run compilation job for gcc
function client_session:_gcc_iorunv(program, argv, opt)
    -- TODO, do distcc compilation
    local outdata, errdata = os.iorunv(program, argv, opt)

    return outdata, errdata
end

-- run compilation job for g++
function client_session:_gxx_iorunv(program, argv, opt)
    return self:_gcc_iorunv(program, argv, opt)
end

-- run compilation job for clang
function client_session:_clang_iorunv(program, argv, opt)
    return self:_gcc_iorunv(program, argv, opt)
end

-- run compilation job for clang++
function client_session:_clangxx_iorunv(program, argv, opt)
    return self:_gcc_iorunv(program, argv, opt)
end

-- get work directory
function client_session:workdir()
    return path.join(self:server():workdir(), "sessions", self:id())
end

function client_session:__tostring()
    return string.format("<session %s>", self:id())
end

function main(client, session_id, job_id, sock)
    local instance = client_session()
    instance:init(client, session_id, job_id, sock)
    return instance
end
