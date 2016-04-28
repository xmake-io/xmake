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
-- @file        lib.lua
--

-- imports
import("utils.vsenv")

-- init it
function init(shellname)
    
    -- save the shell name
    _g.shellname = shellname or "lib.exe"
end

-- get the property
function get(name)

    -- get it
    return _g[name]
end

-- run command
function run(...)

    -- enter vs envirnoment
    vsenv.enter()

    -- run it
    os.run(...)

    -- leave vs envirnoment
    vsenv.leave()
end

-- check the given flags 
function check(flags)

    -- enter vs envirnoment
    vsenv.enter()

    -- check it
    os.run("%s", _g.shellname, ifelse(flags, flags, ""))

    -- leave vs envirnoment
    vsenv.leave()
end

