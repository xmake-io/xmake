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
-- @file        vs200x.lua
--

-- imports
import("core.project.project")
import("vsfile")

-- make
function make(outputdir)

    -- enter project directory
    local olddir = os.cd(project.directory())

    --[[
    local slnfile = vsfile.open(path.join(outputdir, "vs2008.sln"), "w")
    if slnfile then

        slnfile:print("Microsoft Visual Studio Solution File, Format Version 10.00")
        slnfile:print("# Visual Studio 2008")
        slnfile:enter("Project")
            slnfile:enter("ProjectSection(ProjectDependencies) = postProject")
                slnfile:print("{ED657C29-5162-4124-AF9D-0F5889E7868A} = {ED657C29-5162-4124-AF9D-0F5889E7868A}")
            slnfile:leave("EndProjectSection")
        slnfile:leave("EndProject")
        slnfile:enter("Project")
        slnfile:leave("EndProject")
        slnfile:enter("Global")
            slnfile:enter("ProjectSection(ProjectDependencies) = postProject")
                slnfile:enter("ProjectSection(ProjectDependencies) = postProject")
                    slnfile:print("1111")
                    slnfile:print("1111")
                    slnfile:print("1111")
                    slnfile:print("1111")
                slnfile:leave("EndProjectSection")
            slnfile:leave("EndProjectSection")

            slnfile:enter("ProjectSection(ProjectDependencies) = postProject")
                slnfile:print("1111")
            slnfile:leave("EndProjectSection")
        slnfile:leave("EndGlobal")

        slnfile:close()
    end
    ]]

    -- leave project directory
    os.cd(olddir)
end
