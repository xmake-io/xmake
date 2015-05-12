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
-- @file        _xmake_main.lua
--

-- init namespace: xmake
xmake               = xmake or {}
xmake._ARGV         = _ARGV
xmake._PLAT         = _PLAT
xmake._ARCH         = _ARCH
xmake._VERSION      = "XMake v1.0.1"
xmake._PROGRAM_DIR  = _PROGRAM_DIR
xmake._SCRIPTS_DIR  = _PROGRAM_DIR .. "/scripts/"
xmake._OPTIONS      = {}
xmake._CONFIGS      = {}

-- init package path
package.path = xmake._SCRIPTS_DIR .. "?.lua;" .. package.path

-- load modules
local main = require("base/main")

-- the main function
function _xmake_main()
    return main.done()
end
