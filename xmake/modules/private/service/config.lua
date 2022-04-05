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
-- @file        config.lua
--

-- imports
import("core.base.object")

-- define module
local config = config or object()

-- init config
function config:init()
end

-- get the listen address
function config:addr()
    return "127.0.0.1"
end

-- get the listen port
function config:port()
    return 90091
end

-- get class
function config:class()
    return config
end

function config:__tostring()
    return "<config>"
end

function main()
    local instance = config()
    instance:init()
    return instance
end
