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
local sandbox_core_platform_installer = sandbox_core_platform_installer or {}

-- load modules
local platform      = require("platform/platform")
local installer     = require("platform/installer")
local raise         = require("sandbox/modules/raise")

-- install target
function sandbox_core_platform_installer.install(target)
 
    -- enter it
    local ok, errors = installer.install(target)
    if not ok then
        raise(errors)
    end
end

-- uninstall target
function sandbox_core_platform_installer.uninstall(target)
 
    -- enter it
    local ok, errors = installer.uninstall(target)
    if not ok then
        raise(errors)
    end
end

-- return module
return sandbox_core_platform_installer
