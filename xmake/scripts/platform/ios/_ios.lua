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
-- Copyright (C) 2009 - 2015, ruki All rights reserved.
--
-- @author      ruki
-- @file        _ios.lua
--

-- define module: _ios
local _ios = _ios or {}

-- init _ios
function _ios.init(configs)

    -- init the file name formats
    configs.formats = {}
    configs.formats.static = {"lib", ".a"}
    configs.formats.object = {"",    ".o"}
    configs.formats.shared = {"",    ".dylib"}

    -- init the architecture scopes
    configs.archs = {}
    configs.archs.armv7      = {}
    configs.archs.armv7s     = {}
    configs.archs.arm64      = {}

    -- ok
    return true
end


-- return module: _ios
return _ios
