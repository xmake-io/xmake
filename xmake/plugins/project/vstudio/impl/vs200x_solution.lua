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
-- @file        vs200x_solution.lua
--

-- imports
import("core.project.project")
import("vsfile")

-- make header
function _make_header(slnfile, vsinfo)
    slnfile:print("Microsoft Visual Studio Solution File, Format Version %s.00", vsinfo.solution_version)
    slnfile:print("# Visual Studio %s", vsinfo.vstudio_version)
end

-- make projects
function _make_projects(slnfile, vsinfo)

    -- the vstudio tool uuid for vc project
    local vctool = "8BC9CEB8-8B4A-11D0-8D11-00A0C91BC942"

    -- make all targets
    for targetname, target in pairs(project.targets()) do

        -- enter project
        slnfile:enter("Project(\"{%s}\") = \"%s\", \"%s\\%s.vcproj\", \"{%s}\"", vctool, targetname, targetname, targetname, os.uuid(targetname))

        -- add dependences
        for _, dep in ipairs(target:get("deps")) do
            slnfile:enter("ProjectSection(ProjectDependencies) = postProject")
            slnfile:print("{%s} = {%s}", os.uuid(dep), os.uuid(dep))
            slnfile:leave("EndProjectSection")
        end

        -- leave project
        slnfile:leave("EndProject")
    end
end

-- make global
function _make_global(slnfile, vsinfo)

    -- enter global
    slnfile:enter("Global")

    -- add solution configuration platforms
    slnfile:enter("GlobalSection(SolutionConfigurationPlatforms) = preSolution")
    slnfile:print("$(mode)|Win32 = $(mode)|Win32")
    slnfile:leave("EndGlobalSection")

    -- add project configuration platforms
    slnfile:enter("GlobalSection(ProjectConfigurationPlatforms) = postSolution")
    for targetname, _ in pairs(project.targets()) do
        slnfile:print("{%s}.$(mode)|Win32.ActiveCfg = $(mode)|Win32", os.uuid(targetname))
        slnfile:print("{%s}.$(mode)|Win32.Build.0 = $(mode)|Win32", os.uuid(targetname))
    end
    slnfile:leave("EndGlobalSection")

    -- add solution properties
    slnfile:enter("GlobalSection(SolutionProperties) = preSolution")
    slnfile:print("HideSolutionNode = FALSE")
    slnfile:leave("EndGlobalSection")

    -- leave global
    slnfile:leave("EndGlobal")
end

-- make solution
function make(outputdir, vsinfo)

    -- init solution name
    vsinfo.solution_name = project.name() or "vs" .. vsinfo.vstudio_version

    -- open solution file
    local slnfile = vsfile.open(format("%s/vs%s/%s.sln", outputdir, vsinfo.vstudio_version, vsinfo.solution_name), "w")

    -- make header
    _make_header(slnfile, vsinfo)

    -- make projects
    _make_projects(slnfile, vsinfo)

    -- make global
    _make_global(slnfile, vsinfo)

    -- exit solution file
    slnfile:close()
end
