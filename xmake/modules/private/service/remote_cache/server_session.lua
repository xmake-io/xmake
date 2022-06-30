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
import("core.base.bloom_filter")
import("private.service.server_config", {alias = "config"})
import("private.service.message")

-- define module
local server_session = server_session or object()

-- init server session
function server_session:init(server, session_id)
    self._ID = session_id
    self._SERVER = server
end

-- get server session id
function server_session:id()
    return self._ID
end

-- get server
function server_session:server()
    return self._SERVER
end

-- open server session
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

-- close server session
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

-- pull file
function server_session:pull(respmsg)
    local body = respmsg:body()
    local stream = self:stream()
    local cachekey = body.filename
    local cachefile = path.join(self:cachedir(), cachekey:sub(1, 2), cachekey)
    local cacheinfofile = cachefile .. ".txt"
    vprint("pull cachefile(%s) ..", cachekey)

    -- send cache file
    if os.isfile(cachefile) then
        body.exists = true
        if os.isfile(cacheinfofile) then
            body.extrainfo = io.load(cacheinfofile)
        end
        if not stream:send_file(cachefile, {compress = os.filesize(cachefile) > 4096}) then
            raise("send %s failed!", cachefile)
        end
    else
        body.exists = false
        if not stream:send_emptydata() then
            raise("send empty data failed!")
        end
    end
end

-- push file
function server_session:push(respmsg)
    local body = respmsg:body()
    local stream = self:stream()
    local cachekey = body.filename
    local cachefile = path.join(self:cachedir(), cachekey:sub(1, 2), cachekey)
    local cacheinfofile = cachefile .. ".txt"
    vprint("push cachefile(%s) ..", cachekey)
    if not stream:recv_file(cachefile) then
        raise("recv %s failed!", cachefile)
    end
    if body.extrainfo then
        io.save(cacheinfofile, body.extrainfo)
    end
end

-- get file info
function server_session:fileinfo(respmsg)
    local body = respmsg:body()
    local stream = self:stream()
    local cachekey = body.filename
    local cachefile = path.join(self:cachedir(), cachekey:sub(1, 2), cachekey)
    body.fileinfo = {filesize = os.filesize(cachefile), exists = os.isfile(cachefile)}
    vprint("get cacheinfo(%s)", cachekey)
end

-- get exist info
function server_session:existinfo(respmsg)
    local body = respmsg:body()
    local stream = self:stream()
    local cachedir = self:cachedir()
    local filter = bloom_filter.new()
    local count = 0
    vprint("get existinfo(%s) ..", body.name)
    for _, objectfile in ipairs(os.files(path.join(cachedir, "*", "*"))) do
        local cachekey = path.basename(objectfile)
        if cachekey then
            filter:set(cachekey)
            count = count + 1
        end
    end
    if count > 0 then
        if not stream:send_data(filter:data(), {compress = true}) then
            raise("send data failed!")
        end
    else
        if not stream:send_emptydata() then
            raise("send empty data failed!")
        end
    end
    body.count = count
    vprint("get existinfo(%s): %d ok", body.name, count)
end

-- clean files
function server_session:clean()
    vprint("%s: clean files in %s ..", self, self:cachedir())
    os.tryrm(self:cachedir())
    vprint("%s: clean files ok", self)
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
    return path.join(self:server():workdir(), "sessions", self:id())
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

-- get cache directory
function server_session:cachedir()
    return path.join(self:workdir(), "cache")
end

function server_session:__tostring()
    return string.format("<session %s>", self:id())
end

function main(server, session_id)
    local instance = server_session()
    instance:init(server, session_id)
    return instance
end
