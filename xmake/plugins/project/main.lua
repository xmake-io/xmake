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
import("vstudio.vs2005")
import("vstudio.vs2008")

-- make project
function _make(kind)

    -- the maps
    local maps = 
    {
        makefile    = makefile.make
    ,   vs2005      = vs2005.make
    ,   vs2008      = vs2008.make
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
