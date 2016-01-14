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
xmake                   = xmake or {}
xmake._ARGV             = _ARGV
xmake._HOST             = _HOST
xmake._ARCH             = _ARCH
xmake._NULDEV           = _NULDEV
xmake._VERSION          = _VERSION
xmake._PROGRAM_DIR      = _PROGRAM_DIR
xmake._PROJECT_DIR      = _PROJECT_DIR
xmake._CORE_DIR         = _PROGRAM_DIR .. "/core"
xmake._PACKAGES_DIR     = _PROGRAM_DIR .. "/packages"
xmake._TEMPLATES_DIR    = _PROGRAM_DIR .. "/templates"
xmake._PROJECT_FILE     = "xmake.lua"
xmake._OPTIONS          = {}
xmake._CONFIGS          = {}

-- init package path
package.path = xmake._CORE_DIR .. "/?.lua;" .. package.path

-- load modules
local main = require("base/main")

-- the main function
function _xmake_main()

    -- done main
    return main.done()
end
