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
-- Copyright (C) 2015-present, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        vs201x_solution.lua
--

-- imports
import("core.project.project")
import("vsfile")
import("vsutils")

-- make header
function _make_header(slnfile, vsinfo)
    slnfile:print("Microsoft Visual Studio Solution File, Format Version %s.00", vsinfo.solution_version)
    slnfile:print("# Visual Studio %s", vsinfo.vstudio_version)
end

-- make projects
function _make_projects(slnfile, vsinfo)

    -- make all targets
    local groups = {}
    local targets = {}
    local vctool = "8BC9CEB8-8B4A-11D0-8D11-00A0C91BC942"
    for targetname, target in table.orderpairs(project.targets()) do
        -- we need to set startup project for default or binary target
        -- @see https://github.com/xmake-io/xmake/issues/1249
        if target:get("default") == true then
            table.insert(targets, 1, target)
        elseif target:is_binary() then
            local first_target = targets[1]
            if not first_target or first_target:get("default") ~= true then
                table.insert(targets, 1, target)
            else
                table.insert(targets, target)
            end
        else
            table.insert(targets, target)
        end
    end
    for _, target in ipairs(targets) do
        local targetname = target:name()
        slnfile:enter("Project(\"{%s}\") = \"%s\", \"%s\\%s.vcxproj\", \"{%s}\"", vctool, targetname, targetname, targetname, hash.uuid4(targetname))
        for _, dep in ipairs(target:get("deps")) do
            slnfile:enter("ProjectSection(ProjectDependencies) = postProject")
            slnfile:print("{%s} = {%s}", hash.uuid4(dep), hash.uuid4(dep))
            slnfile:leave("EndProjectSection")
        end
        slnfile:leave("EndProject")
        local group_path = target:get("group")
        if group_path and #(group_path:trim()) > 0 then
            local group_current_path
            local group_names = path.split(group_path)
            for idx, group_name in ipairs(group_names) do
                group_current_path = group_current_path and path.join(group_current_path, group_name) or group_name
                groups[group_current_path] = hash.uuid4("group." .. group_current_path)
            end
        end
    end

    -- make all groups
    local project_group_uuid = "2150E333-8FDC-42A3-9474-1A3956D46DE8"
    for group_path, group_uuid in table.orderpairs(groups) do
        local group_name = path.filename(group_path)
        slnfile:enter("Project(\"{%s}\") = \"%s\", \"%s\", \"{%s}\"",
            project_group_uuid, group_name, group_name, group_uuid)
        slnfile:leave("EndProject")
    end
end

-- make global
function _make_global(slnfile, vsinfo)

    -- enter global
    slnfile:enter("Global")

    -- add solution configuration platforms
    slnfile:enter("GlobalSection(SolutionConfigurationPlatforms) = preSolution")
    for _, mode in ipairs(vsinfo.modes) do
        for _, arch in ipairs(vsinfo.archs) do
            slnfile:print("%s|%s = %s|%s", mode, arch, mode, arch)
        end
    end
    slnfile:leave("EndGlobalSection")

    -- add project configuration platforms
    slnfile:enter("GlobalSection(ProjectConfigurationPlatforms) = postSolution")
    for targetname, target in table.orderpairs(project.targets()) do
        for _, mode in ipairs(vsinfo.modes) do
            for _, arch in ipairs(vsinfo.archs) do
                local vs_arch = vsutils.vsarch(arch)
                slnfile:print("{%s}.%s|%s.ActiveCfg = %s|%s", hash.uuid4(targetname), mode, arch, mode, vs_arch)
                slnfile:print("{%s}.%s|%s.Build.0 = %s|%s", hash.uuid4(targetname), mode, arch, mode, vs_arch)
            end
        end
    end
    slnfile:leave("EndGlobalSection")

    -- add solution properties
    slnfile:enter("GlobalSection(SolutionProperties) = preSolution")
    slnfile:print("HideSolutionNode = FALSE")
    slnfile:leave("EndGlobalSection")

    -- add project groups
    slnfile:enter("GlobalSection(NestedProjects) = preSolution")
    local subgroups = {}
    for targetname, target in table.orderpairs(project.targets()) do
        local group_path = target:get("group")
        if group_path then
            -- target -> group
            group_path = path.normalize(group_path)
            slnfile:print("{%s} = {%s}", hash.uuid4(targetname), hash.uuid4("group." .. group_path))
            -- group -> group -> ...
            local group_current_path
            local group_names = path.split(group_path)
            for idx, group_name in ipairs(group_names) do
                group_current_path = group_current_path and path.join(group_current_path, group_name) or group_name
                local group_name_sub = group_names[idx + 1]
                local key = group_name .. (group_name_sub or "")
                if group_name_sub and not subgroups[key] then
                    slnfile:print("{%s} = {%s}", hash.uuid4("group." .. path.join(group_current_path, group_name_sub)),
                        hash.uuid4("group." .. group_current_path))
                    subgroups[key] = true
                end
            end
        end
    end
    slnfile:leave("EndGlobalSection")

    -- leave global
    slnfile:leave("EndGlobal")
end

-- make solution
function make(vsinfo)

    -- init solution name
    vsinfo.solution_name = project.name() or ("vs" .. vsinfo.vstudio_version)

    -- open solution file
    local slnpath = path.join(vsinfo.solution_dir, vsinfo.solution_name .. ".sln")
    local slnfile = vsfile.open(slnpath, "w")

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

