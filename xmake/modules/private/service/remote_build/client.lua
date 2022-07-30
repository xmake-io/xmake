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
-- @file        client.lua
--

-- imports
import("core.base.tty")
import("core.base.bytes")
import("core.base.base64")
import("core.base.socket")
import("core.base.option")
import("core.base.scheduler")
import("core.project.config", {alias = "project_config"})
import("lib.detect.find_tool")
import("private.service.client_config", {alias = "config"})
import("private.service.message")
import("private.service.client")
import("private.service.stream", {alias = "socket_stream"})
import("private.service.remote_build.filesync", {alias = "new_filesync"})

-- define module
local remote_build_client = remote_build_client or client()
local super = remote_build_client:class()

-- init client
function remote_build_client:init()
    super.init(self)

    -- init address
    local address = assert(config.get("remote_build.connect"), "config(remote_build.connect): not found!")
    self:address_set(address)

    -- get project directory
    local projectdir = os.projectdir()
    local projectfile = os.projectfile()
    if projectfile and os.isfile(projectfile) and projectdir then
        self._PROJECTDIR = projectdir
        self._WORKDIR = path.join(project_config.directory(), "remote_build")
    else
        raise("we need enter a project directory with xmake.lua first!")
    end

    -- init filesync
    local filesync = new_filesync(self:projectdir(), path.join(self:workdir(), "manifest.txt"))
    filesync:ignorefiles_add(".git/**")
    filesync:ignorefiles_add(".xmake/**")
    self._FILESYNC = filesync

    -- init timeout
    self._SEND_TIMEOUT = config.get("remote_build.send_timeout") or config.get("send_timeout") or -1
    self._RECV_TIMEOUT = config.get("remote_build.recv_timeout") or config.get("recv_timeout") or -1
    self._CONNECT_TIMEOUT = config.get("remote_build.connect_timeout") or config.get("connect_timeout") or -1
end

-- get class
function remote_build_client:class()
    return remote_build_client
end

-- connect to the remote server
function remote_build_client:connect()
    if self:is_connected() then
        print("%s: has been connected!", self)
        return
    end

    -- we need user authorization?
    local token = config.get("remote_build.token")
    if not token and self:user() then

        -- get user password
        cprint("Please input user ${bright}%s${clear} password to connect <%s:%d>:", self:user(), self:addr(), self:port())
        io.flush()
        local pass = (io.read() or ""):trim()
        assert(pass ~= "", "password is empty!")

        -- compute user authorization
        token = base64.encode(self:user() .. ":" .. pass)
        token = hash.md5(bytes(token))
    end

    -- do connect
    local addr = self:addr()
    local port = self:port()
    local sock = assert(socket.connect(addr, port, {timeout = self:connect_timeout()}), "%s: server unreachable!", self)
    local session_id = self:session_id()
    local ok = false
    local errors
    print("%s: connect %s:%d ..", self, addr, port)
    if sock then
        local stream = socket_stream(sock, {send_timeout = self:send_timeout(), recv_timeout = self:recv_timeout()})
        if stream:send_msg(message.new_connect(session_id, {token = token})) and stream:flush() then
            local msg = stream:recv_msg()
            if msg then
                vprint(msg:body())
                if msg:success() then
                    ok = true
                else
                    errors = msg:errors()
                end
            end
        end
    end
    if ok then
        print("%s: connected!", self)
    else
        print("%s: connect %s:%d failed, %s", self, addr, port, errors or "unknown")
    end

    -- update status
    local status = self:status()
    status.addr = addr
    status.port = port
    status.token = token
    status.connected = ok
    status.session_id = session_id
    self:status_save()

    -- sync files
    if ok then
        self:sync()
    end
end

-- disconnect server
function remote_build_client:disconnect()
    if not self:is_connected() then
        print("%s: has been disconnected!", self)
        return
    end
    local addr = self:addr()
    local port = self:port()
    local sock = socket.connect(addr, port, {timeout = self:connect_timeout()})
    local session_id = self:session_id()
    local errors
    local ok = false
    print("%s: disconnect %s:%d ..", self, addr, port)
    if sock then
        local stream = socket_stream(sock, {send_timeout = self:send_timeout(), recv_timeout = self:recv_timeout()})
        if stream:send_msg(message.new_disconnect(session_id, {token = self:token()})) and stream:flush() then
            local msg = stream:recv_msg()
            if msg then
                vprint(msg:body())
                if msg:success() then
                    ok = true
                else
                    errors = msg:errors()
                end
            end
        end
    else
        -- server unreachable, but we still disconnect it.
        wprint("%s: server unreachable!", self)
        ok = true
    end
    if ok then
        print("%s: disconnected!", self)
    else
        print("%s: disconnect %s:%d failed, %s", self, addr, port, errors or "unknown")
    end

    -- update status
    local status = self:status()
    status.token = nil
    status.connected = not ok
    self:status_save()
end

-- sync server files
function remote_build_client:sync()
    assert(self:is_connected(), "%s: has been not connected!", self)
    local addr = self:addr()
    local port = self:port()
    local sock = assert(socket.connect(addr, port, {timeout = self:connect_timeout()}), "%s: server unreachable!", self)
    local session_id = self:session_id()
    local errors
    local ok = false
    local diff_files
    print("%s: sync files in %s:%d ..", self, addr, port)
    while sock do

        -- diff files
        local stream = socket_stream(sock, {send_timeout = self:send_timeout(), recv_timeout = self:recv_timeout()})
        diff_files, errors = self:_diff_files(stream)
        if not diff_files then
            break
        end
        if not diff_files.changed then
            ok = true
            break
        end

        -- do sync
        cprint("Uploading files ..")
        local send_ok = false
        if stream:send_msg(message.new_sync(session_id, diff_files, {token = self:token()}), {compress = true}) and stream:flush() then
            if self:_send_diff_files(stream, diff_files) then
                send_ok = true
            end
        end
        if not send_ok then
            errors = "send files failed"
            break
        end

        -- sync ok
        local msg = stream:recv_msg({timeout = -1})
        if msg and msg:success() then
            vprint(msg:body())
            ok = true
        elseif msg then
            errors = msg:errors()
        end
        break
    end
    if ok then
        print("%s: sync files ok!", self)
    else
        print("%s: sync files failed in %s:%d, %s", self, addr, port, errors or "unknown")
    end
end

-- pull server files
function remote_build_client:pull(filepattern, outputdir)
    assert(self:is_connected(), "%s: has been not connected!", self)
    local addr = self:addr()
    local port = self:port()
    local sock = assert(socket.connect(addr, port, {timeout = self:connect_timeout()}), "%s: server unreachable!", self)
    local session_id = self:session_id()
    local errors
    local ok = false
    if not filepattern:find("*", 1, true) and os.isdir(filepattern) then
        filepattern = path.join(filepattern, "**")
    end
    print("%s: pull %s in %s:%d ..", self, filepattern, addr, port)
    local stream = socket_stream(sock, {send_timeout = self:send_timeout(), recv_timeout = self:recv_timeout()})
    if stream:send_msg(message.new_pull(session_id, filepattern, {token = self:token()})) and stream:flush() then
        local fileitems
        local msg = stream:recv_msg({timeout = -1})
        if msg then
            dprint(msg:body())
            if msg:success() then
                fileitems = msg:body().fileitems
            else
                errors = msg:errors()
            end
        end
        if fileitems then
            for _, fileitem in ipairs(fileitems) do
                print("recving %s ..", fileitem)
                if not stream:recv_file(path.normalize(path.join(outputdir, fileitem))) then
                    errors = string.format("recv %s failed", fileitem)
                    break
                end
            end
            msg = stream:recv_msg({timeout = -1})
            if msg then
                dprint(msg:body())
                if msg:success() then
                    ok = true
                else
                    errors = msg:errors()
                end
            end
        end
    end
    if ok then
        print("%s: pull files to %s!", self, outputdir)
    else
        print("%s: pull files failed in %s:%d, %s", self, addr, port, errors or "unknown")
    end
end

-- clean server files
function remote_build_client:clean()
    assert(self:is_connected(), "%s: has been not connected!", self)
    local addr = self:addr()
    local port = self:port()
    local sock = assert(socket.connect(addr, port, {timeout = self:connect_timeout()}), "%s: server unreachable!", self)
    local session_id = self:session_id()
    local errors
    local ok = false
    print("%s: clean files in %s:%d ..", self, addr, port)
    local stream = socket_stream(sock, {send_timeout = self:send_timeout(), recv_timeout = self:recv_timeout()})
    if stream:send_msg(message.new_clean(session_id, {token = self:token()})) and stream:flush() then
        local msg = stream:recv_msg({timeout = -1})
        if msg then
            vprint(msg:body())
            if msg:success() then
                ok = true
            else
                errors = msg:errors()
            end
        end
    end
    if ok then
        print("%s: clean files ok!", self)
    else
        print("%s: clean files failed in %s:%d, %s", self, addr, port, errors or "unknown")
    end
end

-- run command
function remote_build_client:runcmd(program, argv)
    assert(self:is_connected(), "%s: has been not connected!", self)
    local addr = self:addr()
    local port = self:port()
    local sock = assert(socket.connect(addr, port, {timeout = self:connect_timeout()}), "%s: server unreachable!", self)
    local session_id = self:session_id()
    local errors
    local ok = false
    local buff = bytes(8192)
    local command = os.args(table.join(program, argv))
    local leftstr = ""
    cprint("%s: run ${bright}%s${clear} in %s:%d ..", self, command, addr, port)
    local stream = socket_stream(sock, {send_timeout = self:send_timeout(), recv_timeout = self:recv_timeout()})
    if stream:send_msg(message.new_runcmd(session_id, program, argv, {token = self:token()})) and stream:flush() then
        local stdin_opt = {stop = false}
        local group_name = "remote_build/runcmd"
        scheduler.co_group_begin(group_name, function (co_group)
            scheduler.co_start(self._read_stdin, self, stream, stdin_opt)
        end)
        while true do
            local msg = stream:recv_msg({timeout = -1})
            if msg then
                if msg:is_data() then
                    local data = stream:recv(buff, msg:body().size)
                    if data then
                        leftstr = leftstr .. data:str()
                        local pos = leftstr:lastof("\n", true)
                        if pos then
                            cprint(leftstr:sub(1, pos - 1))
                            leftstr = leftstr:sub(pos + 1)
                        end
                    else
                        errors = string.format("recv output data(%d) failed!", msg:body().size)
                        break
                    end
                elseif msg:is_end() then
                    ok = true
                    break
                else
                    if msg:success() then
                        ok = true
                    else
                        errors = msg:errors()
                    end
                    break
                end
            else
                break
            end
        end
        stdin_opt.stop = true
        scheduler.co_group_wait(group_name)
    end
    if #leftstr > 0 then
        cprint(leftstr)
    end
    if ok then
        print("%s: run command ok!", self)
    else
        print("%s: run command failed in %s:%d, %s", self, addr, port, errors or "unknown")
    end
    io.flush()
end

-- is connected?
function remote_build_client:is_connected()
    return self:status().connected
end

-- get the status
function remote_build_client:status()
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
function remote_build_client:status_save()
    io.save(self:statusfile(), self:status())
end

-- get the status file
function remote_build_client:statusfile()
    return path.join(self:workdir(), "status.txt")
end

-- get the project directory
function remote_build_client:projectdir()
    return self._PROJECTDIR
end

-- get working directory
function remote_build_client:workdir()
    return self._WORKDIR
end

-- get user token
function remote_build_client:token()
    return self:status().token
end

-- get the session id, only for unique project
function remote_build_client:session_id()
    return self:status().session_id or hash.uuid():split("-", {plain = true})[1]:lower()
end

-- set the given client address
function remote_build_client:address_set(address)
    local addr, port, user = self:address_parse(address)
    self._ADDR = addr
    self._PORT = port
    self._USER = user
end

-- get user name
function remote_build_client:user()
    return self._USER
end

-- get the ip address
function remote_build_client:addr()
    return self._ADDR
end

-- get the address port
function remote_build_client:port()
    return self._PORT
end

-- get filesync
function remote_build_client:_filesync()
    return self._FILESYNC
end

-- diff server files
function remote_build_client:_diff_files(stream)
    assert(self:is_connected(), "%s: has been not connected!", self)
    print("Scanning files ..")
    local filesync = self:_filesync()
    local manifest, filecount = filesync:snapshot()
    local session_id = self:session_id()
    local count = 0
    local result, errors
    cprint("Comparing ${bright}%d${clear} files ..", filecount)
    if stream:send_msg(message.new_diff(session_id, manifest, {token = self:token()}), {compress = true}) and stream:flush() then
        local msg = stream:recv_msg({timeout = -1})
        if msg and msg:success() then
            result = msg:body().manifest
            if result then
                for _, fileitem in ipairs(result.inserted) do
                    if count < 8 then
                        cprint("    ${green}[+]: ${clear}%s", fileitem)
                        count = count + 1
                    end
                end
                for _, fileitem in ipairs(result.modified) do
                    if count < 8 then
                        cprint("    ${yellow}[*]: ${clear}%s", fileitem)
                        count = count + 1
                    end
                end
                for _, fileitem in ipairs(result.removed) do
                    if count < 8 then
                        cprint("    ${red}[-]: ${clear}%s", fileitem)
                        count = count + 1
                    end
                end
                if count >= 8 then
                    print("    ...")
                end
            end
        elseif msg then
            errors = msg:errors()
        end
    end
    cprint("${bright}%d${clear} files has been changed!", count)
    return result, errors
end

-- send diff files
function remote_build_client:_send_diff_files(stream, diff_files)
    local count = 0
    local totalsize = 0
    local compressed_size = 0
    local totalcount = #(diff_files.inserted or {}) + #(diff_files.modified or {})
    local time = os.mclock()
    local startime = time
    for _, fileitem in ipairs(diff_files.inserted) do
        local filesize = os.filesize(fileitem)
        if os.mclock() - time > 1000 then
            cprint("Uploading ${bright}%d%%${clear} ..", math.floor(count * 100 / totalcount))
            time = os.mclock()
        end
        vprint("uploading %s, %d bytes ..", fileitem, filesize)
        local sent, compressed_real = stream:send_file(fileitem, {compress = filesize > 4096})
        if not sent then
            return false
        end
        count = count + 1
        totalsize = totalsize + filesize
        compressed_size = compressed_size + compressed_real
    end
    for _, fileitem in ipairs(diff_files.modified) do
        local filesize = os.filesize(fileitem)
        if os.mclock() - time > 1000 then
            cprint("Uploading ${bright}%d%%${clear} ..", math.floor(count * 100 / totalcount))
            time = os.mclock()
        end
        vprint("uploading %s, %d bytes ..", fileitem, filesize)
        local sent, compressed_real = stream:send_file(fileitem, {compress = filesize > 4096})
        if not sent then
            return false
        end
        count = count + 1
        totalsize = totalsize + filesize
        compressed_size = compressed_size + compressed_real
    end
    cprint("Uploading ${bright}%s%%${clear} ..", totalcount > 0 and math.floor(count * 100 / totalcount) or 0)
    cprint("${bright}%s${clear} files, ${bright}%s (%s%%)${clear} bytes are uploaded, spent ${bright}%s${clear} ms.",
        totalcount, compressed_size, totalsize > 0 and math.floor(compressed_size * 100 / totalsize) or 0, os.mclock() - startime)
    return stream:flush()
end

-- read stdin data
function remote_build_client:_read_stdin(stream, opt)
    local term = tty.term()
    if term == "msys2" or term == "cygwin" then
        wprint("we cannot capture stdin on %s, please pass `-y` option to xmake command or use cmd/powershell terminal!", term)
    end
    while not opt.stop do
        -- FIXME, io.readable is invalid on msys2/cygwin, it always return false
        -- @see https://github.com/xmake-io/xmake/issues/2504
        if io.readable() then
            local line = io.read("L") -- with crlf
            if line and #line > 0 then
                local ok = false
                local data = bytes(line)
                if stream:send_msg(message.new_data(0, data:size(), {token = self:token()})) then
                    if stream:send(data) and stream:flush() then
                        ok = true
                    end
                end
                if not ok then
                    break
                end
            end
        else
            os.sleep(500)
        end
    end
    -- say bye
    if stream:send_msg(message.new_end(self:session_id(), {token = self:token()})) then
        stream:flush()
    end
end

function remote_build_client:__tostring()
    return "<remote_build_client>"
end

-- is connected? we cannot depend on client:init when run action
function is_connected()
    -- the current process is in service? we cannot enable it
    if os.getenv("XMAKE_IN_SERVICE") then
        return false
    end
    local projectdir = os.projectdir()
    local projectfile = os.projectfile()
    if projectfile and os.isfile(projectfile) and projectdir then
        local workdir = path.join(project_config.directory(), "remote_build")
        local statusfile = path.join(workdir, "status.txt")
        if os.isfile(statusfile) then
            local status = io.load(statusfile)
            if status and status.connected then
                return true
            end
        end
    end
end

-- new a client instance
function new()
    local instance = remote_build_client()
    instance:init()
    return instance
end

-- get the singleton
function singleton()
    local instance = _g.singleton
    if not instance then
        config.load()
        instance = new()
        _g.singleton = instance
    end
    return instance
end

function main()
    return new()
end
