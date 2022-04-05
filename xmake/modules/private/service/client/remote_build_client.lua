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
-- @file        remote_build_client.lua
--

-- imports
import("private.service.config")
import("private.service.client.client")

-- define module
local remote_build_client = remote_build_client or client()
local super = remote_build_client:class()

-- init client
function remote_build_client:init()
    super.init(self)
end

-- get class
function remote_build_client:class()
    return remote_build_client
end

function remote_build_client:__tostring()
    return "<remote_build_client>"
end

function main()
    local instance = remote_build_client()
    instance:init()
    return instance
end
