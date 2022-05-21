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
-- @file        clean_files.lua
--

-- imports
import("core.base.option")
import("core.base.scheduler")
import("private.service.client_config", {alias = "config"})
import("private.service.remote_build.client", {alias = "remote_build_client"})
import("private.service.remote_cache.client", {alias = "remote_cache_client"})
import("private.service.distcc_build.client", {alias = "distcc_build_client"})

function _clean_remote_build_server(...)
    remote_build_client(...):clean()
end

function _clean_remote_cache_server(...)
    remote_cache_client(...):clean()
end

function _clean_distcc_build_server(...)
    distcc_build_client(...):clean()
end

function main(...)
    local cleaners = {}
    local default = true
    if option.get("remote") then
        table.insert(cleaners, _clean_remote_build_server)
        default = false
    end
    if option.get("distcc") then
        table.insert(cleaners, _clean_distcc_build_server)
        default = false
    end
    if option.get("ccache") then
        table.insert(cleaners, _clean_remote_cache_server)
        default = false
    end
    if default then
        if config.get("remote_build") then
            table.insert(cleaners, _clean_remote_build_server)
        end
    end
    for _, clean_server in ipairs(cleaners) do
        scheduler.co_start(clean_server, ...)
    end
end


