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
-- @file        main.lua
--

-- imports
import("core.base.option")
import("core.project.task")
import("core.platform.environment")
import("makefile.makefile")
import("vstudio.vs2002")
import("vstudio.vs2003")
import("vstudio.vs2005")
import("vstudio.vs2008")
import("vstudio.vs2010")
import("vstudio.vs2012")
import("vstudio.vs2013")
import("vstudio.vs2015")
import("vstudio.vs2017")

-- make project
function _make(kind)

    -- the maps
    local maps = 
    {
        makefile    = makefile.make
    ,   vs2002      = vs2002.make
    ,   vs2003      = vs2003.make
    ,   vs2005      = vs2005.make
    ,   vs2008      = vs2008.make
    ,   vs2010      = vs2010.make
    ,   vs2012      = vs2012.make
    ,   vs2013      = vs2013.make
    ,   vs2015      = vs2015.make
    ,   vs2017      = vs2017.make
    }
    assert(maps[kind], "the project kind(%s) is not supported!", kind)
    
    -- make it
    maps[kind](option.get("outputdir"))
end

-- main
function main()

    -- config it first
    task.run("config")

    -- enter toolchains environment
    environment.enter("toolchains")

    -- make project
    _make(option.get("kind"))

    -- leave toolchains environment
    environment.leave("toolchains")

    -- trace
    cprint("${bright}create ok!${ok_hand}")
end
