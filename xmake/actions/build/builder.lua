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
-- @file        builder.lua
--

-- imports
import("core.base.option")
import("core.project.task")
import("core.project.config")
import("core.project.project")
import("core.project.cache")
import("core.tool.tool")

-- get target
function _target(targetname)

    -- get and check it
    return assert(project.target(targetname), "unknown target: %s", targetname)
end

-- make the given target
function _make_target(target)

    -- make for all dependent targets
    for _, depname in ipairs(target:get("deps")) do
        _make_target(_target(depname))
    end

    -- trace
    print("make target: %s", target:name())
end

-- make
function make(targetname)

    -- make all targets
    if targetname == "all" then

        -- make all targets
        for _, target in pairs(project.targets()) do
            _make_target(target)
        end
    else

        -- make target
        _make_target(_target(targetname))
    end
end

-- make from makefile
function make_from_makefile(targetname)

    -- check target
    if targetname ~= "all" then
        _target(targetname)
    end

    -- make makefile
    task.run("makefile", {output = path.join(config.get("buildir"), "makefile")})

    -- run make
    tool.run("make", path.join(config.get("buildir"), "makefile"), targetname, option.get("jobs"))
end
