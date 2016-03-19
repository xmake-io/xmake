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
-- @file        makefile.lua
--

-- imports
import("core.project.project")

-- make target
function _make_target(makefile, target)


end

-- make all
function _make_all(makefile)

    -- make all first
    local all = ""
    for targetname, _ in pairs(project.targets()) do
        -- append the target name to all
        all = all .. " " .. targetname
    end
    makefile:printf("all: %s\n\n", all)
    makefile:printf(".PHONY: all %s\n\n", all)

    -- make it for all targets
    for _, target in pairs(project.targets()) do

        -- make target
        _make_target(makefile, target)

        -- append the target name to all
        all = all .. " " .. target:name()
    end
   
end

-- make
function make()

    -- enter project directory
    os.cd("$(projectdir)")

    -- remove the log file first
    os.rm("$(buildir)/.build.log")

    -- open the makefile
    local makefile = io.open("$(buildir)/makefile", "w")

    -- make all
    _make_all(makefile)

    -- close the makefile
    makefile:close()
 
    -- leave project directory
    os.cd("-")

end
