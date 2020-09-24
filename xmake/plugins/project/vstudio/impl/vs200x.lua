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
-- @file        vs200x.lua
--

-- imports
import("core.project.project")
import("vs200x_solution")
import("vs200x_vcproj")

-- make vstudio project
function make(outputdir, vsinfo)

    -- enter project directory
    local oldir = os.cd(project.directory())

    -- init solution directory
    vsinfo.solution_dir = path.join(outputdir, "vs" .. vsinfo.vstudio_version)

    -- make solution
    vs200x_solution.make(vsinfo)

    -- TODO
    -- disable precompiled header first
    for _, target in pairs(project.targets()) do
        target:set("pcheader", nil)
        target:set("pcxxheader", nil)
    end

    -- make vsprojs
    for _, target in pairs(project.targets()) do
        if not target:isphony() then
            vs200x_vcproj.make(vsinfo, target)
        end
    end

    -- leave project directory
    os.cd(oldir)
end
