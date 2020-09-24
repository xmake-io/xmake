--!A cross-platform build utility based on Lua
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--
-- Copyright (C) 2015-2020, TBOOX Open Source Group.
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
        if not target:isphony() then

            -- enter project
            slnfile:enter("Project(\"{%s}\") = \"%s\", \"%s\\%s.vcproj\", \"{%s}\"", vctool, targetname, targetname, targetname, hash.uuid4(targetname))

            -- add dependences
            for _, dep in ipairs(target:get("deps")) do
                slnfile:enter("ProjectSection(ProjectDependencies) = postProject")
                slnfile:print("{%s} = {%s}", hash.uuid4(dep), hash.uuid4(dep))
                slnfile:leave("EndProjectSection")
            end

            -- leave project
            slnfile:leave("EndProject")
        end
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
    for targetname, target in pairs(project.targets()) do
        if not target:isphony() then
            slnfile:print("{%s}.$(mode)|Win32.ActiveCfg = $(mode)|Win32", hash.uuid4(targetname))
            slnfile:print("{%s}.$(mode)|Win32.Build.0 = $(mode)|Win32", hash.uuid4(targetname))
        end
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
function make(vsinfo)

    -- init solution name
    vsinfo.solution_name = project.name() or ("vs" .. vsinfo.vstudio_version)

    -- open solution file
    local slnfile = vsfile.open(path.join(vsinfo.solution_dir, vsinfo.solution_name .. ".sln"), "w")

    -- init indent character
    vsfile.indentchar('\t')

    -- make header
    _make_header(slnfile, vsinfo)

    -- make projects
    _make_projects(slnfile, vsinfo)

    -- make global
    _make_global(slnfile, vsinfo)

    -- exit solution file
    slnfile:close()
end
