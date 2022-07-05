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
-- @file        server.lua
--

-- imports
import("core.base.global")
import("private.service.server_config", {alias = "config"})
import("private.service.message")
import("private.service.server")
import("private.service.remote_cache.server_session")
import("lib.detect.find_tool")

-- define module
local remote_cache_server = remote_cache_server or server()
local super = remote_cache_server:class()

-- init server
function remote_cache_server:init(daemon)
    super.init(self, daemon)

    -- init address
    local address = assert(config.get("remote_cache.listen"), "config(remote_cache.listen): not found!")
    super.address_set(self, address)

    -- init handler
    super.handler_set(self, self._on_handle)

    -- init sessions
    self._SESSIONS = {}

    -- init timeout
    self._SEND_TIMEOUT = config.get("remote_cache.send_timeout") or config.get("send_timeout") or -1
    self._RECV_TIMEOUT = config.get("remote_cache.recv_timeout") or config.get("recv_timeout") or -1
end

-- get class
function remote_cache_server:class()
    return remote_cache_server
end

-- get work directory
function remote_cache_server:workdir()
    local workdir = config.get("remote_cache.workdir")
    if not workdir then
        workdir = path.join(global.directory(), "service", "server", "remote_cache")
    end
    return workdir
end

-- on handle message
function remote_cache_server:_on_handle(stream, msg)
    local session_id = msg:session_id()
    local session = self:_session(session_id)
    vprint("%s: %s: <session %s>: on handle message(%d)", self, stream:sock(), session_id, msg:code())
    vprint(msg:body())
    session:stream_set(stream)
    local respmsg = msg:clone()
    local session_errs
    local session_ok = try
    {
        function()
            if self:need_verfiy() then
                local ok, errors = self:verify_user(msg:token(), stream:sock():peeraddr())
                if not ok then
                    session_errs = errors
                    return false
                end
            end
            if msg:is_connect() then
                session:open()
            elseif msg:is_disconnect() then
                session:close()
                self._SESSIONS[session_id] = nil
            else
                assert(session:is_connected(), "session has not been connected!")
                if msg:is_push() then
                    session:push(respmsg)
                elseif msg:is_pull() then
                    session:pull(respmsg)
                elseif msg:is_fileinfo() then
                    session:fileinfo(respmsg)
                elseif msg:is_existinfo() then
                    session:existinfo(respmsg)
                elseif msg:is_clean() then
                    session:clean()
                end
            end
            return true
        end,
        catch
        {
            function (errors)
                if errors then
                    session_errs = tostring(errors)
                    vprint(session_errs)
                end
            end
        }
    }
    respmsg:status_set(session_ok)
    if not session_ok and session_errs then
        respmsg:errors_set(session_errs)
    end
    local ok = stream:send_msg(respmsg) and stream:flush()
    vprint("%s: %s: <session %s>: send %s", self, stream:sock(), session_id, ok and "ok" or "failed")
end

-- get session
function remote_cache_server:_session(session_id)
    local session = self._SESSIONS[session_id]
    if not session then
        session = server_session(self, session_id)
        self._SESSIONS[session_id] = session
    end
    return session
end

-- close session
function remote_cache_server:_session_close(session_id)
    self._SESSIONS[session_id] = nil
end

function remote_cache_server:__tostring()
    return "<remote_cache_server>"
end

function main(daemon)
    local instance = remote_cache_server()
    instance:init(daemon ~= nil)
    return instance
end
