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
import("private.service.remote_build.filesync", {alias = "new_filesync"})

-- define module
local server_session = server_session or object()

-- init server session
function server_session:init(server, session_id)
    self._ID = session_id
    self._SERVER = server
    local filesync = new_filesync(self:sourcedir(), path.join(self:workdir(), "manifest.txt"))
    filesync:ignorefiles_add(".git/**")
    filesync:ignorefiles_add(".xmake/**")
    self._FILESYNC = filesync
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

    -- ensure source directory
    self:_ensure_sourcedir()

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

-- set stream
function server_session:stream_set(stream)
    self._STREAM = stream
end

-- get stream
function server_session:stream()
    return self._STREAM
end

-- diff files
function server_session:diff(respmsg)
    local body = respmsg:body()
    vprint("%s: diff files in %s ..", self, self:sourcedir())

    -- ensure sourcedir
    self:_ensure_sourcedir()

    -- do snapshot
    local filesync = self:_filesync()
    local manifest_server = assert(filesync:snapshot(), "server manifest not found!")
    local manifest_client = assert(body.manifest, "client manifest not found!")

    -- get all files
    local fileitems = hashset.new()
    for fileitem, _ in pairs(manifest_client) do
        fileitems:insert(fileitem)
    end
    for fileitem, _ in pairs(manifest_server) do
        fileitems:insert(fileitem)
    end

    -- do diff
    local removed = {}
    local modified = {}
    local inserted = {}
    local changed = false
    for _, fileitem in fileitems:keys() do
        local manifest_info_client = manifest_client[fileitem]
        local manifest_info_server = manifest_server[fileitem]
        if manifest_info_client and manifest_info_server
            and manifest_info_client.sha256 ~= manifest_info_server.sha256 then
            table.insert(modified, fileitem)
            changed = true
            vprint("[*]: %s", fileitem)
        elseif not manifest_info_server and manifest_info_client then
            table.insert(inserted, fileitem)
            changed = true
            vprint("[+]: %s", fileitem)
        elseif manifest_info_server and not manifest_info_client then
            table.insert(removed, fileitem)
            changed = true
            vprint("[-]: %s", fileitem)
        end
    end
    body.manifest = {changed = changed, removed = removed, inserted = inserted, modified = modified}
    vprint("%s: diff files ok", self)
end

-- sync files
function server_session:sync(respmsg)
    local body = respmsg:body()
    local stream = self:stream()
    local manifest = assert(body.manifest, "manifest not found!")
    local filesync = self:_filesync()
    local sourcedir = self:sourcedir()
    local archivedir = os.tmpfile() .. ".dir"
    vprint("%s: sync files in %s ..", self, self:sourcedir())
    if self:_recv_syncfiles(manifest, archivedir) then

        -- do sync
        for _, fileitem in ipairs(manifest.inserted) do
            vprint("[+]: %s", fileitem)
            local filepath_server = path.join(sourcedir, fileitem)
            local filepath_client = path.join(archivedir, fileitem)
            os.cp(filepath_client, filepath_server)
            filesync:update(fileitem, filepath_server)
        end
        for _, fileitem in ipairs(manifest.modified) do
            vprint("[*]: %s", fileitem)
            local filepath_server = path.join(sourcedir, fileitem)
            local filepath_client = path.join(archivedir, fileitem)
            os.cp(filepath_client, filepath_server)
            filesync:update(fileitem, filepath_server)
        end
        for _, fileitem in ipairs(manifest.removed) do
            vprint("[-]: %s", fileitem)
            local filepath_server = path.join(sourcedir, fileitem)
            os.rm(filepath_server)
            filesync:remove(fileitem)
        end
        filesync:manifest_save()
    else
        raise("receive files failed!")
    end
    os.tryrm(archivedir)
    vprint("%s: sync files ok", self)
end

-- pull file
function server_session:pull(respmsg)
    local body = respmsg:body()
    local stream = self:stream()
    local filepattern = body.filename
    vprint("pull %s ..", filepattern)

    -- get files
    local filepaths = os.files(path.join(self:sourcedir(), filepattern))
    local fileitems = {}
    for _, filepath in ipairs(filepaths) do
        local fileitem = path.relative(filepath, self:sourcedir())
        if is_host("windows") then
            fileitem = fileitem:gsub("\\", "/")
        end
        if fileitem:startswith("./") then
            fileitem = fileitem:sub(3)
        end
        table.insert(fileitems, fileitem)
    end
    vprint(fileitems)

    -- send files
    body.fileitems = fileitems
    respmsg:status_set(true)
    if stream:send_msg(respmsg) then
        for _, fileitem in ipairs(fileitems) do
            local filepath = path.join(self:sourcedir(), fileitem)
            vprint("sending %s ..", filepath)
            if not stream:send_file(filepath, {compress = os.filesize(filepath) > 4096}) then
                raise("send %s failed!", filepath)
            end
        end
    end
end

-- clean files
function server_session:clean()
    vprint("%s: clean files in %s ..", self, self:workdir())
    os.tryrm(self:workdir())
    vprint("%s: clean files ok", self)
end

-- run command
function server_session:runcmd(respmsg)
    local body = respmsg:body()
    local program = body.program
    local argv = body.argv
    vprint("%s: run command(%s) ..", self, os.args(table.join(program, argv)))

    -- init pipes
    local stdin_rpipe, stdin_wpipe = pipe.openpair("BA") -- rpipe (block)
    local stdin_wpipeopt = {wpipe = stdin_wpipe, stop = false}
    local stdout_rpipe, stdout_wpipe = pipe.openpair()
    local stdout_rpipeopt = {rpipe = stdout_rpipe, stop = false}

    -- read and write pipe
    local group_name = "remote_build/runcmd"
    scheduler.co_group_begin(group_name, function (co_group)
        scheduler.co_start(self._write_pipe, self, stdin_wpipeopt)
        scheduler.co_start(self._read_pipe, self, stdout_rpipeopt)
    end)

    -- run program
    os.execv(program, argv, {curdir = self:sourcedir(), stdout = stdout_wpipe, stdin = stdin_rpipe, envs = {XMAKE_IN_SERVICE = "true"}})
    stdin_rpipe:close()
    stdout_wpipe:close()

    -- stop it
    stdin_wpipeopt.stop = true
    stdout_rpipeopt.stop = true

    -- wait pipes exits
    scheduler.co_group_wait(group_name)
    vprint("%s: run command ok", self)
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

-- get sourcedir directory
function server_session:sourcedir()
    return path.join(self:workdir(), "source")
end

-- get filesync
function server_session:_filesync()
    return self._FILESYNC
end

-- ensure source directory
function server_session:_ensure_sourcedir()
    local sourcedir = self:sourcedir()
    if not os.isdir(sourcedir) then
        os.mkdir(sourcedir)
    end
end

-- write data to pipe
function server_session:_write_pipe(opt)
    local buff = bytes(256)
    local wpipe = opt.wpipe
    vprint("%s: %s: writing data ..", self, wpipe)
    while not opt.stop do
        local data = self:_recv_data(buff)
        if data then
            local real = wpipe:write(data, {block = true})
            vprint("%s: %s: write bytes(%d)", self, wpipe, real)
            if real < 0 then
                break
            end
        else
            break
        end
    end
    wpipe:close()
    vprint("%s: %s: write data end", self, wpipe)
end

-- read data from pipe
function server_session:_read_pipe(opt)
    local buff = bytes(256)
    local rpipe = opt.rpipe
    local verbose = option.get("verbose")
    vprint("%s: %s: reading data ..", self, rpipe)
    local leftstr = ""
    while not opt.stop do
        local real, data = rpipe:read(buff)
        if real > 0 then
            if verbose then
                leftstr = leftstr .. data:str()
                local pos = leftstr:lastof("\n", true)
                if pos then
                    cprint(leftstr:sub(1, pos - 1))
                    leftstr = leftstr:sub(pos + 1)
                end
            end
            if not self:_send_data(data) then
                break
            end
        elseif real == 0 then
            if rpipe:wait(pipe.EV_READ, -1) < 0 then
                break
            end
        else
            break
        end
    end
    rpipe:close()
    if #leftstr > 0 then
        cprint(leftstr)
    end
    -- say end to client
    self:_send_end()
    vprint("%s: %s: read data end", self, rpipe)
end

-- recv data from stream
function server_session:_recv_data(buff)
    local stream = self:stream()
    local msg = stream:recv_msg({timeout = -1})
    if msg and msg:is_data() then
        return stream:recv(buff, msg:body().size)
    end
end

-- send data to stream
function server_session:_send_data(data)
    local stream = self:stream()
    if stream:send_msg(message.new_data(self:id(), data:size())) then
        if stream:send(data) then
            return stream:flush()
        end
    end
end

-- send end to stream
function server_session:_send_end()
    local stream = self:stream()
    if stream:send_msg(message.new_end(self:id())) then
        return stream:flush()
    end
end

-- recv syncfiles
function server_session:_recv_syncfiles(manifest, outputdir)
    local stream = self:stream()
    for _, fileitem in ipairs(manifest.inserted) do
        local filepath = path.join(outputdir, fileitem)
        if not stream:recv_file(filepath) then
            dprint("%s: recv %s failed!", self, filepath)
            return false
        end
    end
    for _, fileitem in ipairs(manifest.modified) do
        local filepath = path.join(outputdir, fileitem)
        if not stream:recv_file(filepath) then
            dprint("%s: recv %s failed!", self, filepath)
            return false
        end
    end
    return true
end

function server_session:__tostring()
    return string.format("<session %s>", self:id())
end

function main(server, session_id)
    local instance = server_session()
    instance:init(server, session_id)
    return instance
end
