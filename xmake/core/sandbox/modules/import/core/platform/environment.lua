--!The Make-like Build Utility based on Lua
-- 
-- XMake is free software; you can redistribute it and/or modify
-- it under the terms of the GNU Lesser General Public License as published by
-- the Free Software Foundation; either version 2.1 of the License, or
-- (at your option) any later version.
-- 
-- XMake is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU Lesser General Public License for more details.
-- 
-- You should have received a copy of the GNU Lesser General Public License
-- along with XMake; 
-- If not, see <a href="http://www.gnu.org/licenses/"> http://www.gnu.org/licenses/</a>
-- 
-- Copyright (C) 2015 - 2016, ruki All rights reserved.
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
