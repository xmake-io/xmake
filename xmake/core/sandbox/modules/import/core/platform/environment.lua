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
-- Copyright (C) 2015-2020, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        environment.lua
--

-- define module
local sandbox_core_platform_environment = sandbox_core_platform_environment or {}

-- load modules
local platform      = require("platform/platform")
local environment   = require("platform/environment")
local raise         = require("sandbox/modules/raise")

-- enter the given environment
function sandbox_core_platform_environment.enter(name)

    -- enter it
    local ok, errors = environment.enter(name)
    if not ok then
        raise(errors)
    end
end

-- leave the given environment
function sandbox_core_platform_environment.leave(name)

    -- enter it
    local ok, errors = environment.leave(name)
    if not ok then
        raise(errors)
    end
end

-- return module
return sandbox_core_platform_environment
