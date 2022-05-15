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
import("core.tool.toolchain")
import("core.cache.memcache")
import("private.tools.vstool")
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
function server_session:open(respmsg)
    if self:is_connected() then
        return
    end

    -- get server info
    local body = respmsg:body()
    body.ncpu = os.cpuinfo().ncpu
    body.njob = os.default_njob()

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

-- do clean
function server_session:clean()
    vprint("%s: clean files in %s ..", self, self:workdir())
    os.tryrm(self:workdir())
    vprint("%s: clean files ok", self)
end

-- do compile
function server_session:compile(respmsg)

    -- recv source file
    local body = respmsg:body()
    local stream = self:stream()
    local sourcename = body.sourcename
    local sourcedir = path.join(self:workdir(), (hash.uuid4():gsub("-", "")))
    local sourcefile = path.join(sourcedir, sourcename)
    local objectfile = sourcefile .. ".o"
    if not stream:recv_file(sourcefile) then
        raise("recv %s failed!", sourcename)
    end

    -- do compile
    local errors
    local ok = try
    {
        function ()
            local flags = body.flags
            local toolname = body.toolname
            local compile = assert(self["_" .. toolname .. "_compile"], "%s: compiler(%s) is not supported!", self, toolname)
            compile(self, toolname, flags, sourcefile, objectfile, body)
            return os.isfile(objectfile)
        end,
        catch
        {
            function (errs)
                errors = tostring(errs)
            end
        }
    }

    -- send object file
    if ok then
        if not stream:send_file(objectfile, {compress = os.filesize(objectfile) > 4096}) then
            raise("send %s failed!", objectfile)
        end
    else
        if not stream:send_emptydata() then
            raise("send empty data failed!")
        end
    end

    -- remove files
    os.tryrm(sourcefile)
    os.tryrm(objectfile)
    return ok, errors
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
    return path.join(self:server():workdir(), "sessons", self:id())
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

-- get cache
function server_session:_cache()
    return memcache.cache("distcc_build_server.session")
end

-- get tool
function server_session:_tool(name, opt)
    opt = opt or {}
    local plat = opt.plat
    local arch = opt.arch
    local toolkind = opt.toolkind
    local cachekey = name .. (plat or "") .. (arch or "") .. toolkind
    local cacheinfo = self:_cache():get(cachekey)
    if not cacheinfo then
        local toolchain_configs = (config.get("distcc_build.toolchains") or {})[name]
        local toolchain_inst = toolchain.load(name, table.join({plat = plat, arch = arch}, toolchain_configs))
        if toolchain_inst:check() then
            local program, toolname = toolchain_inst:tool(toolkind)
            assert(program, "%s/%s not found!", name, toolkind)
            cacheinfo = {program, toolname, toolchain_inst:runenvs()}
            self:_cache():set(cachekey, cacheinfo)
        else
            raise("toolchain(%s) not found!", name)
        end
    end
    return cacheinfo[1], cacheinfo[2], cacheinfo[3]
end

-- do compile job for gcc
function server_session:_gcc_compile(toolname, flags, sourcefile, objectfile, opt)
    local program, toolname_real, runenvs = self:_tool(opt.toolchain, opt)
    assert(toolname_real == toolname, "toolname is not matched, %s != %s", toolname, toolname_real)
    os.iorunv(program, table.join(flags, "-o", objectfile, sourcefile), {envs = runenvs})
end

-- do compile job for g++
function server_session:_gxx_compile(toolname, flags, sourcefile, objectfile, opt)
    return self:_gcc_compile(toolname, flags, sourcefile, objectfile, opt)
end

-- do compile job for clang
function server_session:_clang_compile(toolname, flags, sourcefile, objectfile, opt)
    return self:_gcc_compile(toolname, flags, sourcefile, objectfile, opt)
end

-- do compile job for clang++
function server_session:_clangxx_compile(toolname, flags, sourcefile, objectfile, opt)
    return self:_gcc_compile(toolname, flags, sourcefile, objectfile, opt)
end

-- do compile job for cl
function server_session:_cl_compile(toolname, flags, sourcefile, objectfile, opt)
    local program, toolname_real, runenvs = self:_tool(opt.toolchain, opt)
    assert(toolname_real == toolname, "toolname is not matched, %s != %s", toolname, toolname_real)
    vstool.iorunv(program, table.join(flags, "-Fo" .. objectfile, sourcefile), {envs = runenvs})
end

function server_session:__tostring()
    return string.format("<session %s>", self:id())
end

function main(server, session_id)
    local instance = server_session()
    instance:init(server, session_id)
    return instance
end
