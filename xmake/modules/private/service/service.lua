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
import("core.base.scheduler")
import("private.service.remote_build.server", {alias = "remote_build_server"})
import("private.service.distcc_build.server", {alias = "distcc_build_server"})

function _start_remote_build_server(...)
    remote_build_server(...):runloop()
end

function _start_distcc_build_server(...)
    distcc_build_server(...):runloop()
end

function main(...)
    local starters = {}
    if option.get("remote") then
        table.insert(starters, _start_remote_build_server)
    elseif option.get("distcc") then
        table.insert(starters, _start_distcc_build_server)
    else
        table.insert(starters, _start_remote_build_server)
        table.insert(starters, _start_distcc_build_server)
    end
    for _, start_server in ipairs(starters) do
        scheduler.co_start(start_server, ...)
    end
end

