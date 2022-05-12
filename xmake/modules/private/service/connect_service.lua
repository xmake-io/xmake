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
-- @file        connect_service.lua
--

-- imports
import("core.base.option")
import("core.base.scheduler")
import("private.service.client_config", {alias = "config"})
import("private.service.remote_build.client", {alias = "remote_build_client"})
import("private.service.distcc_build.client", {alias = "distcc_build_client"})

function _connect_remote_build_server(...)
    remote_build_client(...):connect()
end

function _connect_distcc_build_server(...)
    distcc_build_client(...):connect()
end

function main(...)
    local connectors = {}
    if option.get("remote") then
        table.insert(connectors, _connect_remote_build_server)
    elseif option.get("distcc") then
        table.insert(connectors, _connect_distcc_build_server)
    else
        if config.get("remote_build") then
            table.insert(connectors, _connect_remote_build_server)
        end
    end
    for _, connect_server in ipairs(connectors) do
        scheduler.co_start(connect_server, ...)
    end
end

