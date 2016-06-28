--!The Automatic Cross-platform Build Tool
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
-- @file        installer.lua
--

-- define module
local installer = installer or {}

-- load modules
local platform  = require("platform/platform")
local sandbox   = require("sandbox/sandbox")

-- load the given installer from the given platform
function installer.load(plat)

    -- load platform
    local instance, errors = platform.load(plat)
    if not instance then
        return nil, errors
    end

    -- get installer
    return instance:installer()
end

-- install the target for the current platform
function installer.install(target, plat)

    -- load the installer module
    local module, errors = installer.load()
    if not module and errors then
        return false, errors
    end

    -- install it
    if module then
        local ok, errors = sandbox.load(module.install, target)
        if not ok then
            return false, errors
        end
    end

    -- ok
    return true
end

-- uninstall target for the current platform
function installer.uninstall(target)

    -- load the installer module
    local module, errors = installer.load()
    if not module and errors then
        return false, errors
    end

    -- uninstall it
    if module then
        local ok, errors = sandbox.load(module.uninstall, target)
        if not ok then
            return false, errors
        end
    end

    -- ok
    return true
end

-- return module
return installer
