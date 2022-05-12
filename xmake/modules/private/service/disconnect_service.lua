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
-- @file        disconnect_service.lua
--

-- imports
import("core.base.option")
import("core.base.scheduler")
import("private.service.client_config", {alias = "config"})
import("private.service.remote_build.client", {alias = "remote_build_client"})
import("private.service.distcc_build.client", {alias = "distcc_build_client"})

function _disconnect_remote_build_server(...)
    remote_build_client(...):disconnect()
end

function _disconnect_distcc_build_server(...)
    distcc_build_client(...):disconnect()
end

function main(...)
    local disconnectors = {}
    if option.get("remote") then
        table.insert(disconnectors, _disconnect_remote_build_server)
    elseif option.get("distcc") then
        table.insert(disconnectors, _disconnect_distcc_build_server)
    else
        if config.get("remote_build") then
            table.insert(disconnectors, _disconnect_remote_build_server)
        end
    end
    for _, disconnect_server in ipairs(disconnectors) do
        scheduler.co_start(disconnect_server, ...)
    end
end


