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
xmake = xmake or {}

-- init some global variables for xmake
xmake._ARGV         = _ARGV
xmake._VERBOSE      = _VERBOSE
xmake._PROGRAM_DIR  = _PROGRAM_DIR
xmake._PROJECT_DIR  = _PROJECT_DIR
xmake._SCRIPTS_DIR  = _PROGRAM_DIR .. "/scripts/"

-- init namespace: xmake.main
xmake.main = {}
local main = xmake.main

-- load built-in scripts
local scripts = dofile(xmake._SCRIPTS_DIR .. "_scripts.lua")
for i = 1, #scripts do
    dofile(xmake._SCRIPTS_DIR .. scripts[i])
end

-- the main entry function
function _xmake_main()
    xmake.trace("hello world!");
    return 0
end
