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
local environment = environment or {}

-- load modules
local platform  = require("platform/platform")
local sandbox   = require("sandbox/sandbox")

-- load the given environment from the given platform
function environment.load(plat)

    -- load platform
    local instance, errors = platform.load(plat)
    if not instance then
        return nil, errors
    end

    -- get environment
    return instance:environment()
end

-- enter the environment for the current platform
function environment.enter(name)

    -- load the environment module
    local module, errors = environment.load()
    if not module and errors then
        return false, errors
    end

    -- enter it
    if module then
        local ok, errors = sandbox.load(module.enter, name)
        if not ok then
            return false, errors
        end
    end

    -- ok
    return true
end

-- leave the environment for the current platform
function environment.leave(name)

    -- load the environment module
    local module, errors = environment.load()
    if not module and errors then
        return false, errors
    end

    -- leave it
    if module then
        local ok, errors = sandbox.load(module.leave, name)
        if not ok then
            return false, errors
        end
    end

    -- ok
    return true
end

-- return module
return environment
