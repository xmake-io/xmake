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
import("core.base.bytes")
import("core.base.socket")
import("core.base.scheduler")
import("core.project.config", {alias = "project_config"})
import("devel.git")
import("lib.detect.find_tool")
import("private.service.config")
import("private.service.message")
import("private.service.client")
import("private.service.stream", {alias = "socket_stream"})
import("private.service.remote_build.environment")

-- define module
local remote_build_client = remote_build_client or client()
local super = remote_build_client:class()

-- init client
function remote_build_client:init()
    super.init(self)

    -- init address
    local address = assert(config.get("remote_build.client.connect"), "config(remote_build.client.connect): not found!")
    super.address_set(self, address)

    -- get project directory
    local projectdir = os.projectdir()
    local projectfile = os.projectfile()
    if projectfile and os.isfile(projectfile) and projectdir then
        self._PROJECTDIR = projectdir
        self._WORKDIR = path.join(project_config.directory(), "remote_build")
    else
        raise("we need enter a project directory with xmake.lua first!")
    end

    -- enter git environment
    environment.enter()
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
    local addr = self:addr()
    local port = self:port()
    local sock = socket.connect(addr, port)
    local session_id = self:session_id()
    local ok = false
    local errors
    print("%s: connect %s:%d ..", self, addr, port)
    if sock then
        local stream = socket_stream(sock)
        if stream:send_msg(message.new_connect(session_id)) and stream:flush() then
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
    local sock = socket.connect(addr, port)
    local session_id = self:session_id()
    local errors
    local ok = false
    print("%s: disconnect %s:%d ..", self, addr, port)
    if sock then
        local stream = socket_stream(sock)
        if stream:send_msg(message.new_disconnect(session_id)) and stream:flush() then
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
        print("%s: disconnected!", self)
    else
        print("%s: disconnect %s:%d failed, %s", self, addr, port, errors or "unknown")
    end

    -- update status
    local status = self:status()
    status.connected = not ok
    self:status_save()
end

-- sync server files
function remote_build_client:sync()
    assert(self:is_connected(), "%s: has been not connected!", self)
    local addr = self:addr()
    local port = self:port()
    local sock = socket.connect(addr, port)
    local session_id = self:session_id()
    local errors
    local ok = false
    print("%s: sync files in %s:%d ..", self, addr, port)
    if sock then
        local stream = socket_stream(sock)
        if stream:send_msg(message.new_sync(session_id, true)) and stream:flush() then
            local msg = stream:recv_msg()
            if msg and msg:success() then
                vprint(msg:body())
                self:_do_syncfiles(msg:body().path, msg:body().branch)
                if stream:send_msg(message.new_sync(session_id, false)) and stream:flush() then
                    msg = stream:recv_msg()
                    if msg and msg:success() then
                        ok = true
                    elseif msg then
                        errors = msg:errors()
                    end
                end
            elseif msg then
                errors = msg:errors()
            end
        end
    end
    if ok then
        print("%s: sync files ok!", self)
    else
        print("%s: sync files failed in %s:%d, %s", self, addr, port, errors or "unknown")
    end
end

-- clean server files
function remote_build_client:clean()
    assert(self:is_connected(), "%s: has been not connected!", self)
    local addr = self:addr()
    local port = self:port()
    local sock = socket.connect(addr, port)
    local session_id = self:session_id()
    local errors
    local ok = false
    print("%s: clean files in %s:%d ..", self, addr, port)
    if sock then
        local stream = socket_stream(sock)
        if stream:send_msg(message.new_clean(session_id)) and stream:flush() then
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
    local sock = socket.connect(addr, port)
    local session_id = self:session_id()
    local errors
    local ok = false
    local buff = bytes(8192)
    local command = os.args(table.join(program, argv))
    local leftstr = ""
    cprint("%s: run ${bright}%s${clear} in %s:%d ..", self, command, addr, port)
    if sock then
        local stream = socket_stream(sock)
        if stream:send_msg(message.new_runcmd(session_id, program, argv)) and stream:flush() then
            local stdin_opt = {stop = false}
            scheduler.co_start(self._read_stdin, self, stream, stdin_opt)
            while true do
                local msg = stream:recv_msg()
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
        end
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

-- get the session id, only for unique project
function remote_build_client:session_id()
    return self:status().session_id or hash.uuid():split("-", {plain = true})[1]:lower()
end

-- do syncfiles, e.g. git push user@addr:remote_path branch:remote_branch
--
-- @note on Windows/OpenSSH, we need solve the following issues
-- https://github.com/PowerShell/Win32-OpenSSH/wiki/Setting-up-a-Git-server-on-Windows-using-Git-for-Windows-and-Win32_OpenSSH
--
-- 1. Set powershell as default shell
-- @code
-- New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell -Value "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -PropertyType String -Force
-- New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShellCommandOption -Value "/c" -PropertyType String -Force
-- @endcode
--
-- 2. Set git/mingw64/bin to %PATH%, to solve `git-receive-pack not found!`
-- @code
-- $gitPath = Join-Path -Path $env:ProgramFiles -ChildPath "git\mingw64\bin"
-- $machinePath = [Environment]::GetEnvironmentVariable('Path', 'MACHINE')
-- [Environment]::SetEnvironmentVariable('Path', "$gitPath;$machinePath", 'Machine')
-- @endcode
--
function remote_build_client:_do_syncfiles(remote_path, remote_branch)
    local user = assert(config.get("remote_build.client.user"), "config(remote_build.client.user): not found!")
    local addr = self:addr()
    assert(remote_path, "git remote path not found!")
    assert(remote_branch, "git remote branch not found!")

    -- push to remote
    local remote_url = string.format("%s@%s:%s", user, addr, remote_path)
    git.push(remote_url, {remote_branch = remote_branch, verbose = true})
end

-- read stdin data
function remote_build_client:_read_stdin(stream, opt)
    while not opt.stop do
        if io.readable() then
            local line = io.read("L") -- with crlf
            if line and #line > 0 then
                local ok = false
                local data = bytes(line)
                if stream:send_msg(message.new_data(0, data:size())) then
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
end


function remote_build_client:__tostring()
    return "<remote_build_client>"
end

-- is connected? we cannot depend on client:init when run action
function is_connected()
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

function main()
    local instance = remote_build_client()
    instance:init()
    return instance
end
