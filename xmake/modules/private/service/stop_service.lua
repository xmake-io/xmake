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
-- @file        stop_service.lua
--

-- imports
import("core.base.option")
import("private.service.remote_build.server", {alias = "remote_build_server"})
import("private.service.remote_cache.server", {alias = "remote_cache_server"})
import("private.service.distcc_build.server", {alias = "distcc_build_server"})

function _stop_remote_build_server(...)
    local pidfile = remote_build_server(...):pidfile()
    if pidfile and os.isfile(pidfile) then
        local pid = io.readfile(pidfile)
        if pid then
            pid = pid:trim()
            try { function ()
                if is_host("windows") then
                    os.run("taskkill /f /t /pid %s", pid)
                else
                    os.run("kill -9 %s", pid)
                end
                print("service[%s]: stopped", pid)
            end}
        end
        os.rm(pidfile)
    end
end

function _stop_remote_cache_server(...)
    local pidfile = remote_cache_server(...):pidfile()
    if pidfile and os.isfile(pidfile) then
        local pid = io.readfile(pidfile)
        if pid then
            pid = pid:trim()
            try { function ()
                if is_host("windows") then
                    os.run("taskkill /f /t /pid %s", pid)
                else
                    os.run("kill -9 %s", pid)
                end
                print("service[%s]: stopped", pid)
            end}
        end
        os.rm(pidfile)
    end
end

function _stop_distcc_build_server(...)
    local pidfile = distcc_build_server(...):pidfile()
    if pidfile and os.isfile(pidfile) then
        local pid = io.readfile(pidfile)
        if pid then
            pid = pid:trim()
            try { function ()
                if is_host("windows") then
                    os.run("taskkill /f /t /pid %s", pid)
                else
                    os.run("kill -9 %s", pid)
                end
                print("service[%s]: stopped", pid)
            end}
        end
        os.rm(pidfile)
    end
end

function main(...)
    local stoppers = {_stop_remote_build_server, _stop_remote_cache_server, _stop_distcc_build_server}
    for _, stop_server in ipairs(stoppers) do
        stop_server(...)
    end
end

