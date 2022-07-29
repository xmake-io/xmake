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
import("core.base.socket")
import("core.base.hashset")
import("core.base.scheduler")
import("private.service.client_config", {alias = "config"})
import("private.service.message")
import("private.service.stream", {alias = "socket_stream"})

-- define module
local client_session = client_session or object()

-- init client session
function client_session:init(client, session_id, token, addr, port, opt)
    opt = opt or {}
    self._ID = session_id
    self._ADDR = addr
    self._PORT = port
    self._TOKEN = token
    self._CLIENT = client
    self._SEND_TIMEOUT = opt.send_timeout and opt.send_timeout or -1
    self._RECV_TIMEOUT = opt.recv_timeout and opt.recv_timeout or -1
    self._CONNECT_TIMEOUT = opt.connect_timeout and opt.connect_timeout or -1
end

-- get client session id
function client_session:id()
    return self._ID
end

-- get token
function client_session:token()
    return self._TOKEN
end

-- get client
function client_session:client()
    return self._CLIENT
end

-- get send timeout
function client_session:send_timeout()
    return self._SEND_TIMEOUT
end

-- get recv timeout
function client_session:recv_timeout()
    return self._RECV_TIMEOUT
end

-- get connect timeout
function client_session:connect_timeout()
    return self._CONNECT_TIMEOUT
end

-- server unreachable?
function client_session:is_unreachable()
    return self._UNREACHABLE
end

-- get stream
function client_session:stream()
    local stream = self._STREAM
    if stream == nil then
        local addr = self._ADDR
        local port = self._PORT
        local sock = socket.connect(addr, port, {timeout = self:connect_timeout()})
        if not sock then
            self._UNREACHABLE = true
            raise("%s: server unreachable!", self)
        end
        stream = socket_stream(sock, {send_timeout = self:send_timeout(), recv_timeout = self:recv_timeout()})
        self._STREAM = stream
    end
    return stream
end

-- open session
function client_session:open(host_status)
    assert(not self:is_opened(), "%s: has been opened!", self)
    self._OPENED = true
    self._HOST_STATUS = host_status
end

-- close session
function client_session:close()
    self._OPENED = false
end

-- is opened?
function client_session:is_opened()
    return self._OPENED
end

-- get host status
function client_session:host_status()
    return self._HOST_STATUS
end



-- run compilation job
function client_session:compile(sourcefile, objectfile, cppfile, cppflags, opt)
    assert(self:is_opened(), "%s: has been not opened!", self)
    local ok = false
    local errors
    local tool = opt.tool
    local toolname = tool:name()
    local toolkind = tool:kind()
    local plat = tool:plat()
    local arch = tool:arch()
    local cachekey = opt.cachekey
    local toolchain = tool:toolchain():name()
    local stream = self:stream()
    local host_status = self:host_status()
    local outdata, errdata
    if stream:send_msg(message.new_compile(self:id(), toolname, toolkind, plat, arch, toolchain,
            cppflags, path.filename(sourcefile), {token = self:token(), cachekey = cachekey})) and
        stream:send_file(cppfile, {compress = os.filesize(cppfile) > 4096}) and stream:flush() then
        local recv = stream:recv_file(objectfile, {timeout = -1})
        if recv ~= nil then
            local msg = stream:recv_msg()
            if msg then
                if msg:success() then
                    local body = msg:body()
                    outdata = body.outdata
                    errdata = body.errdata
                    host_status.cpurate = body.cpurate
                    host_status.memrate = body.memrate
                    ok = true
                else
                    errors = msg:errors()
                end
            end
        else
            errors = "recv object file failed!"
        end
    end
    os.tryrm(cppfile)
    assert(ok, errors or "unknown errors!")
    return outdata, errdata
end

-- get work directory
function client_session:workdir()
    return path.join(self:server():workdir(), "sessions", self:id())
end

function client_session:__tostring()
    return string.format("<session %s>", self:id())
end

function main(client, session_id, token, addr, port, opt)
    local instance = client_session()
    instance:init(client, session_id, token, addr, port, opt)
    return instance
end
