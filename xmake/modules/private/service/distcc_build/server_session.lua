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
-- @file        server_session.lua
--

-- imports
import("core.base.pipe")
import("core.base.bytes")
import("core.base.object")
import("core.base.global")
import("core.base.option")
import("core.base.hashset")
import("core.base.scheduler")
import("private.service.server_config", {alias = "config"})
import("private.service.message")

-- define module
local server_session = server_session or object()

-- init server_session
function server_session:init(session_id)
    self._ID = session_id
end

-- get server_session id
function server_session:id()
    return self._ID
end

-- open server_session
function server_session:open()
    if self:is_connected() then
        return
    end

    -- update status
    local status = self:status()
    status.connected = true
    status.session_id = self:id()
    self:status_save()
end

-- close server_session
function server_session:close()
    if not self:is_connected() then
        return
    end

    -- update status
    local status = self:status()
    status.connected = false
    status.session_id = self:id()
    self:status_save()
end

-- set stream
function server_session:stream_set(stream)
    self._STREAM = stream
end

-- get stream
function server_session:stream()
    return self._STREAM
end

-- get work directory
function server_session:workdir()
    local workdir = config.get("distcc_build.workdir")
    if not workdir then
        workdir = path.join(global.directory(), "service", "server", "distcc_build")
    end
    return path.join(workdir, "sessons", self:id())
end

-- is connected?
function server_session:is_connected()
    return self:status().connected
end

-- get the status
function server_session:status()
    local status = self._STATUS
    local statusfile = self:statusfile()
    if not status then
        if os.isfile(statusfile) then
            status = io.load(statusfile)
        end
        status = status or {}
        self._STATUS = status
    end
    return status
end

-- save status
function server_session:status_save()
    io.save(self:statusfile(), self:status())
end

-- get status file
function server_session:statusfile()
    return path.join(self:workdir(), "status.txt")
end

function server_session:__tostring()
    return string.format("<session %s>", self:id())
end

function main(session_id)
    local instance = server_session()
    instance:init(session_id)
    return instance
end
