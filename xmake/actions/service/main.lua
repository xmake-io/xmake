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
-- @file        main.lua
--

-- imports
import("core.base.option")
import("private.service.server_config")
import("private.service.client_config")
import("private.service.start_service")
import("private.service.restart_service")
import("private.service.stop_service")
import("private.service.connect_service")
import("private.service.reconnect_service")
import("private.service.disconnect_service")
import("private.service.clean_files")
import("private.service.sync_files")
import("private.service.add_user")
import("private.service.rm_user")
import("private.service.gen_token")
import("private.service.show_logs")
import("private.service.show_status")

function main()
    -- @note we need load server config before loading client config,
    -- because we need same local token in both configs
    server_config.load()
    client_config.load()
    if option.get("start") then
        start_service({daemon = true})
    elseif option.get("restart") then
        restart_service()
    elseif option.get("stop") then
        stop_service()
    elseif option.get("connect") then
        connect_service()
    elseif option.get("reconnect") then
        reconnect_service()
    elseif option.get("disconnect") then
        disconnect_service()
    elseif option.get("clean") then
        clean_files()
    elseif option.get("sync") then
        sync_files()
    elseif option.get("gen-token") then
        gen_token()
    elseif option.get("add-user") then
        add_user(option.get("add-user"))
    elseif option.get("rm-user") then
        rm_user(option.get("rm-user"))
    elseif option.get("logs") then
        show_logs()
    elseif option.get("status") then
        show_status()
    else
        start_service()
    end
end

