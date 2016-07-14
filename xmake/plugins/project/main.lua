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
import("core.project.config")
import("core.project.global")
import("core.project.project")
import("core.platform.platform")
import("makefile")

-- make makefile
function _make_makefile(outputdir)

    -- make makefile
    makefile.make(path.join(outputdir, "makefile"))
end

-- make project
function _make(kind)

    -- the maps
    local maps = 
    {
        makefile = _make_makefile
    }
    assert(maps[kind], "the project kind(%s) is not supported!", kind)
    
    -- make it
    maps[kind](option.get("outputdir"))
end

-- main
function main()

    -- check xmake.lua
    if not os.isfile(project.file()) then
        raise("xmake.lua not found!")
    end

    -- load project configure
    config.load()

    -- load platform
    platform.load(config.plat())

    -- load project
    project.load()

    -- make project
    _make(option.get("kind"))

    -- trace
    cprint("${bright}create ok!")
end
