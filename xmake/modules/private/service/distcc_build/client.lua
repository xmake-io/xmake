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
import("core.base.base64")
import("core.base.socket")
import("core.base.option")
import("core.base.scheduler")
import("core.project.policy")
import("core.project.config", {alias = "project_config"})
import("lib.detect.find_tool")
import("private.service.client_config", {alias = "config"})
import("private.service.message")
import("private.service.client")
import("private.cache.build_cache")
import("private.service.distcc_build.client_session")
import("private.service.stream", {alias = "socket_stream"})

-- define module
local distcc_build_client = distcc_build_client or client()
local super = distcc_build_client:class()

-- init client
function distcc_build_client:init()
    super.init(self)

    -- init hosts
    local hosts = assert(config.get("distcc_build.hosts"), "config(distcc_build.hosts): not found!")
    self:hosts_set(hosts)

    -- get project directory
    local projectdir = os.projectdir()
    local projectfile = os.projectfile()
    if projectfile and os.isfile(projectfile) and projectdir then
        self._PROJECTDIR = projectdir
        self._WORKDIR = path.join(project_config.directory(), "distcc_build")
    else
        raise("we need enter a project directory with xmake.lua first!")
    end

    -- init timeout
    self._SEND_TIMEOUT = config.get("distcc_build.send_timeout") or config.get("send_timeout") or -1
    self._RECV_TIMEOUT = config.get("distcc_build.recv_timeout") or config.get("recv_timeout") or -1
    self._CONNECT_TIMEOUT = config.get("distcc_build.connect_timeout") or config.get("connect_timeout") or -1
end

-- get class
function distcc_build_client:class()
    return distcc_build_client
end

-- get the client hosts
function distcc_build_client:hosts()
    return self._HOSTS
end

-- set the client hosts
function distcc_build_client:hosts_set(hosts)
    local hostinfos = {}
    for _, host in ipairs(hosts) do
        local hostinfo = {}
        local address = assert(host.connect, "connect address not found in hosts configuration!")
        local addr, port, user = self:address_parse(address)
        if addr and port then
            hostinfo.addr = addr
            hostinfo.port = port
            hostinfo.user = user
            hostinfo.token = host.token
            hostinfo.njob = host.njob
            table.insert(hostinfos, hostinfo)
        end
    end
    self._HOSTS = hostinfos
end

-- get the status of client hosts
function distcc_build_client:hosts_status()
    local hosts_status = self._HOSTS_STATUS
    if hosts_status == nil then
        hosts_status = table.copy(self:status().hosts)
        for _, host_status in pairs(hosts_status) do
            self:_host_status_update(host_status)
        end
        self._HOSTS_STATUS = hosts_status
    end
    return hosts_status
end

-- connect to the distcc server
function distcc_build_client:connect()
    if self:is_connected() then
        print("%s: has been connected!", self)
        return
    end

    -- do connect
    local hosts = self:hosts()
    assert(hosts and #hosts > 0, "hosts not found!")
    local group_name = tostring(self) .. "/connect"
    scheduler.co_group_begin(group_name, function ()
        for _, host in ipairs(hosts) do
            scheduler.co_start(self._connect_host, self, host)
        end
    end)
    scheduler.co_group_wait(group_name)

    -- all hosts are connected?
    local connected = true
    for _, host in ipairs(hosts) do
        if not self:_is_connected(host.addr, host.port) then
            connected = false
        end
    end

    -- update status
    local status = self:status()
    status.connected = connected
    self:status_save()
end

-- disconnect server
function distcc_build_client:disconnect()
    if not self:is_connected() then
        print("%s: has been disconnected!", self)
        return
    end

    -- do disconnect
    local hosts = self:hosts()
    assert(hosts and #hosts > 0, "hosts not found!")
    local group_name = tostring(self) .. "/disconnect"
    scheduler.co_group_begin(group_name, function ()
        for _, host in ipairs(hosts) do
            scheduler.co_start(self._disconnect_host, self, host)
        end
    end)
    scheduler.co_group_wait(group_name)

    -- all hosts are connected?
    local connected = true
    for _, host in ipairs(hosts) do
        if not self:_is_connected(host.addr, host.port) then
            connected = false
        end
    end

    -- update status
    local status = self:status()
    status.connected = connected
    self:status_save()
end

-- is connected?
function distcc_build_client:is_connected()
    return self:status().connected
end

-- get max jobs count
function distcc_build_client:maxjobs()
    local maxjobs = self._MAXJOBS
    if maxjobs == nil then
        maxjobs = 0
        for _, host in pairs(self:status().hosts) do
            maxjobs = maxjobs + host.njob
        end
        self._MAXJOBS = maxjobs
    end
    return maxjobs or 0
end

-- get free jobs count
function distcc_build_client:freejobs()
    local maxjobs = self:maxjobs()
    if maxjobs > 0 then
        local running = (self._RUNNING or 0)
        if running > maxjobs then
            running = maxjobs
        end
        return maxjobs - running
    end
    return 0
end

-- has free jobs?
function distcc_build_client:has_freejobs()
    return self:freejobs() > 0
end

-- clean server files
function distcc_build_client:clean()
    if not self:is_connected() then
        print("%s: has been disconnected!", self)
        return
    end

    -- do disconnect
    local hosts = self:hosts()
    assert(hosts and #hosts > 0, "hosts not found!")
    local group_name = tostring(self) .. "/clean"
    scheduler.co_group_begin(group_name, function ()
        for _, host in ipairs(hosts) do
            scheduler.co_start(self._clean_host, self, host)
        end
    end)
    scheduler.co_group_wait(group_name)
end

-- run compilation job
function distcc_build_client:compile(program, argv, opt)

    -- get free host
    local host = assert(self:_get_freehost(), "free host not found!")

    -- lock this host
    self:_host_status_lock(host)

    -- open the host session
    local session = assert(self:_host_status_session_open(host), "open session failed!")

    -- do preprocess
    opt = opt or {}
    local preprocess = assert(opt.preprocess, "preprocessor not found!")
    local cppinfo = preprocess(program, argv, opt)
    local build_in_local = false
    if cppinfo then
        -- get objectfile from the build cache first
        local cached = false
        local cachekey
        if build_cache.is_enabled(opt.target) then
            cachekey = build_cache.cachekey(program, cppinfo, opt.envs)
            local objectfile_cached, objectfile_infofile = build_cache.get(cachekey)
            if objectfile_cached then
                os.cp(objectfile_cached, cppinfo.objectfile)
                -- we need update mtime for incremental compilation
                -- @see https://github.com/xmake-io/xmake/issues/2620
                os.touch(cppinfo.objectfile, {mtime = os.time()})
                -- we need get outdata/errdata to show warnings,
                -- @see https://github.com/xmake-io/xmake/issues/2452
                if objectfile_infofile and os.isfile(objectfile_infofile) then
                    local extrainfo = io.load(objectfile_infofile)
                    cppinfo.outdata = extrainfo.outdata
                    cppinfo.errdata = extrainfo.errdata
                end
                cached = true
            end
        end

        -- do distcc compilation
        if not cached then
            -- we just compile the large preprocessed file in remote
            if os.filesize(cppinfo.cppfile) > 4096 and not session:is_unreachable() then
                local compile_fallback = opt.compile_fallback
                if compile_fallback then
                    local ok = try
                    {
                        function ()
                            local outdata, errdata = session:compile(cppinfo.sourcefile, cppinfo.objectfile, cppinfo.cppfile, cppinfo.cppflags,
                                table.join(opt, {cachekey = cachekey}))
                            cppinfo.outdata = outdata
                            cppinfo.errdata = errdata
                            return true
                        end,
                        catch
                        {
                            function (errors)
                                if errors and policy.build_warnings() then
                                    cprint("${color.warning}fallback to the local compiler, %s", tostring(errors))
                                end
                            end
                        }
                    }
                    if not ok then
                        -- we fallback to compile original source file if compiling preprocessed file fails.
                        -- https://github.com/xmake-io/xmake/issues/2467
                        local outdata, errdata = compile_fallback()
                        cppinfo.outdata = outdata
                        cppinfo.errdata = errdata
                    end
                else
                    local outdata, errdata = session:compile(cppinfo.sourcefile, cppinfo.objectfile, cppinfo.cppfile, cppinfo.cppflags,
                        table.join(opt, {cachekey = cachekey}))
                    cppinfo.outdata = outdata
                    cppinfo.errdata = errdata
                end
                if cachekey then
                    local extrainfo
                    if cppinfo.outdata and #cppinfo.outdata ~= 0 then
                        extrainfo = extrainfo or {}
                        extrainfo.outdata = cppinfo.outdata
                    end
                    if cppinfo.errdata and #cppinfo.errdata ~= 0 then
                        extrainfo = extrainfo or {}
                        extrainfo.errdata = cppinfo.errdata
                    end
                    build_cache.put(cachekey, cppinfo.objectfile, extrainfo)
                end
            else
                build_in_local = true
            end
        end
    end

    -- close session
    self:_host_status_session_close(host, session)

    -- unlock this host
    self:_host_status_unlock(host)

    -- build in local
    if build_in_local then
        if cppinfo and build_in_local then
            local compile = assert(opt.compile, "compiler not found!")
            local compile_fallback = opt.compile_fallback
            if compile_fallback then
                local ok = try {function () compile(program, cppinfo, opt); return true end}
                if not ok then
                    -- we fallback to compile original source file if compiling preprocessed file fails.
                    -- https://github.com/xmake-io/xmake/issues/2467
                    local outdata, errdata = compile_fallback()
                    cppinfo.outdata = outdata
                    cppinfo.errdata = errdata
                end
            else
                compile(program, cppinfo, opt)
            end
            if build_cache.is_enabled(opt.target) then
                local cachekey = build_cache.cachekey(program, cppinfo, opt.envs)
                if cachekey then
                    local extrainfo
                    if cppinfo.outdata and #cppinfo.outdata ~= 0 then
                        extrainfo = extrainfo or {}
                        extrainfo.outdata = cppinfo.outdata
                    end
                    if cppinfo.errdata and #cppinfo.errdata ~= 0 then
                        extrainfo = extrainfo or {}
                        extrainfo.errdata = cppinfo.errdata
                    end
                    build_cache.put(cachekey, cppinfo.objectfile, extrainfo)
                end
            end
        end
    end
    return cppinfo
end

-- get the status
function distcc_build_client:status()
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
function distcc_build_client:status_save()
    io.save(self:statusfile(), self:status())
end

-- get the status file
function distcc_build_client:statusfile()
    return path.join(self:workdir(), "status.txt")
end

-- get the project directory
function distcc_build_client:projectdir()
    return self._PROJECTDIR
end

-- get working directory
function distcc_build_client:workdir()
    return self._WORKDIR
end

-- get free host
function distcc_build_client:_get_freehost()
    local max_weight = -1
    local host
    if self:has_freejobs() then
        for _, host_status in pairs(self:hosts_status()) do
            if host_status.freejobs > 0 and host_status.weight > max_weight then
                max_weight = host_status.weight
                host = host_status
            end
        end
    end
    return host
end

-- update the host status
function distcc_build_client:_host_status_update(host_status)
    local running  = host_status.running or 0
    if running > host_status.njob then
        running = host_status.njob
    end
    if running < 0 then
        running = 0
    end
    host_status.running  = running
    host_status.freejobs = host_status.njob - host_status.running
    host_status.weight   = host_status.freejobs * (1.0 - (host_status.cpurate or 0))
    if host_status.memrate and host_status.memrate > 0.9 then
        host_status.weight = host_status.weight * (1.0 - (host_status.memrate or 0))
    end
end

-- lock host status
function distcc_build_client:_host_status_lock(host_status)

    -- update the host status
    host_status.running = host_status.running + 1
    self:_host_status_update(host_status)

    -- update the total running status
    local running = (self._RUNNING or 0) + 1
    if running > self:maxjobs() then
        running = self:maxjobs()
    end
    self._RUNNING = running
end

-- unlock host status
function distcc_build_client:_host_status_unlock(host_status)

    -- update the host status
    host_status.running = host_status.running - 1
    self:_host_status_update(host_status)

    -- update the total running status
    local running = self._RUNNING - 1
    if running < 0 then
        running = 0
    end
    self._RUNNING = running
end

-- open host session
function distcc_build_client:_host_status_session_open(host_status)
    host_status.sessions  = host_status.sessions or {}
    host_status.free_sessions = host_status.free_sessions or {}
    local sessions = host_status.sessions
    local free_sessions = host_status.free_sessions
    if #free_sessions > 0 then
        local session = free_sessions[#free_sessions]
        if session and not session:is_opened() then
            table.remove(free_sessions)
            session:open(host_status)
            return session
        end
    end
    local njob = host_status.njob
    for i = 1, njob do
        local session = host_status.sessions[i]
        if not session then
            session = client_session(self, host_status.session_id, host_status.token, host_status.addr, host_status.port,
                {send_timeout = self:send_timeout(), recv_timeout = self:recv_timeout(), connect_timeout = self:connect_timeout()})
            host_status.sessions[i] = session
            session:open(host_status)
            return session
        elseif not session:is_opened() then
            session:open(host_status)
            return session
        end
    end
end

-- close session
function distcc_build_client:_host_status_session_close(host_status, session)
    host_status.free_sessions = host_status.free_sessions or {}
    session:close()
    table.insert(host_status.free_sessions, session)
end

-- get the session id, only for unique project
function distcc_build_client:_session_id(addr, port)
    local hosts = self:status().hosts
    if hosts then
        local host = hosts[addr .. ":" .. port]
        if host then
            return host.session_id
        end
    end
    return hash.uuid():split("-", {plain = true})[1]:lower()
end

-- is connected for the given host
function distcc_build_client:_is_connected(addr, port)
    local hosts = self:status().hosts
    if hosts then
        local host = hosts[addr .. ":" .. port]
        if host then
            return host.connected
        end
    end
end

-- connect to the host
function distcc_build_client:_connect_host(host)
    local addr = host.addr
    local port = host.port
    if self:_is_connected(addr, port) then
        print("%s: %s:%d has been connected!", self, addr, port)
        return
    end

    -- we need user authorization?
    local user = host.user
    local token = host.token
    if not token and user then

        -- get user password
        cprint("Please input user ${bright}%s${clear} password to connect <%s:%d>:", user, addr, port)
        io.flush()
        local pass = (io.read() or ""):trim()
        assert(pass ~= "", "password is empty!")

        -- compute user authorization
        token = base64.encode(self:user() .. ":" .. pass)
        token = hash.md5(bytes(token))
    end

    -- do connect
    local sock = assert(socket.connect(addr, port, {timeout = self:connect_timeout()}), "%s: server unreachable!", self)
    local session_id = self:_session_id(addr, port)
    local ok = false
    local errors
    local ncpu, njob
    print("%s: connect %s:%d ..", self, addr, port)
    if sock then
        local stream = socket_stream(sock, {send_timeout = self:send_timeout(), recv_timeout = self:recv_timeout()})
        if stream:send_msg(message.new_connect(session_id, {token = token})) and stream:flush() then
            local msg = stream:recv_msg()
            if msg then
                local body = msg:body()
                vprint(body)
                if msg:success() then
                    ncpu = body.ncpu
                    njob = body.njob
                    ok = true
                else
                    errors = msg:errors()
                end
            end
        end
    end
    if ok then
        print("%s: %s:%d connected!", self, addr, port)
    else
        print("%s: connect %s:%d failed, %s", self, addr, port, errors or "unknown")
    end

    -- update status
    local status = self:status()
    status.hosts = status.hosts or {}
    status.hosts[addr .. ":" .. port] = {
        addr = addr, port = port, token = token,
        connected = ok, session_id = session_id,
        ncpu = ncpu, njob = host.njob or njob}
    self:status_save()
end

-- disconnect from the host
function distcc_build_client:_disconnect_host(host)
    local addr = host.addr
    local port = host.port
    if not self:_is_connected(addr, port) then
        print("%s: %s:%d has been disconnected!", self, addr, port)
        return
    end

    -- do disconnect
    local token = host.token
    local sock = socket.connect(addr, port, {timeout = self:connect_timeout()})
    local session_id = self:_session_id(addr, port)
    local errors
    local ok = false
    print("%s: disconnect %s:%d ..", self, addr, port)
    if sock then
        local stream = socket_stream(sock, {send_timeout = self:send_timeout(), recv_timeout = self:recv_timeout()})
        if stream:send_msg(message.new_disconnect(session_id, {token = token})) and stream:flush() then
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
        print("%s: %s:%d disconnected!", self, addr, port)
    else
        print("%s: disconnect %s:%d failed, %s", self, addr, port, errors or "unknown")
    end

    -- update status
    local status = self:status()
    status.hosts = status.hosts or {}
    local host_status = status.hosts[addr .. ":" .. port]
    if host_status then
        host_status.token = nil
        host_status.connected = not ok
    end
    self:status_save()
end

-- clean file for the host
function distcc_build_client:_clean_host(host)
    local addr = host.addr
    local port = host.port
    if not self:_is_connected(addr, port) then
        print("%s: %s:%d has been disconnected!", self, addr, port)
        return
    end

    -- do clean
    local token = host.token
    local sock = socket.connect(addr, port, {timeout = self:connect_timeout()})
    local session_id = self:_session_id(addr, port)
    local errors
    local ok = false
    print("%s: clean files in %s:%d ..", self, addr, port)
    if sock then
        local stream = socket_stream(sock, {send_timeout = self:send_timeout(), recv_timeout = self:recv_timeout()})
        if stream:send_msg(message.new_clean(session_id, {token = token})) and stream:flush() then
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
        print("%s: %s:%d clean files ok!", self, addr, port)
    else
        print("%s: clean files %s:%d failed, %s", self, addr, port, errors or "unknown")
    end
end

-- is connected? we cannot depend on client:init when run action
function is_connected()
    local connected = _g.connected
    if connected == nil then
        -- the current process is in service? we cannot enable it
        if os.getenv("XMAKE_IN_SERVICE") then
            connected = false
        end
        if connected == nil then
            local projectdir = os.projectdir()
            local projectfile = os.projectfile()
            if projectfile and os.isfile(projectfile) and projectdir then
                local workdir = path.join(project_config.directory(), "distcc_build")
                local statusfile = path.join(workdir, "status.txt")
                if os.isfile(statusfile) then
                    local status = io.load(statusfile)
                    if status and status.connected then
                        connected = true
                    end
                end
            end
        end
        connected = connected or false
        _g.connected = connected
    end
    return connected
end

-- we can run distcc job?
function is_distccjob()
    if is_connected() then
        local co_running = scheduler.co_running()
        if co_running then
            return co_running:data("distcc.distccjob")
        end
    end
end

-- new a client instance
function new()
    local instance = distcc_build_client()
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
