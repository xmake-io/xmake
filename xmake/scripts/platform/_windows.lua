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
-- @file        _windows.lua
--

-- define module: _windows
local _windows = _windows or {}

-- init _windows
function _windows.init(configs)

    -- init the file name format
    configs.format = {}
    configs.format.static   = {"", ".lib"}
    configs.format.object   = {"", ".obj"}
    configs.format.shared   = {"", ".dll"}
    configs.format.console  = {"", ".exe"}

    -- ok
    return true
end


-- return module: _windows
return _windows
