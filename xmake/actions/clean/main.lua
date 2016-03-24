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
-- @file        main.lua
--

-- imports
import("core.base.option")
import("core.project.config")
import("core.project.global")
import("core.project.project")
import("core.platform.platform")

-- main
function main()

    -- check xmake.lua
    if not os.isfile(project.file()) then
        raise("xmake.lua not found!")
    end

    -- get the target name
    local targetname = option.get("target")

    -- load global configure
    global.load()

    -- load project configure
    config.load(targetname)

    -- load platform
    platform.load(config.plat())

    -- load project
    project.load()

    -- check target
    if targetname and targetname ~= "all" and nil == project.target(targetname) then
        raise("unknown target: %s", targetname)
    end

    -- enter project directory
    os.cd(project.directory())

    -- leave project directory
    os.cd("-")

    -- trace
    print("clean ok!")
    
end
