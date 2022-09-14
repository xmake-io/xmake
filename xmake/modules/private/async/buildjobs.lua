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
-- @file        buildjobs.lua
--

-- imports
import("core.base.hashset")

-- build jobs for node dependencies
function _build_jobs_for_nodedeps(nodes, jobs, rootjob, jobrefs, nodeinfo)
    local targetjob_ref = jobrefs[nodeinfo.name]
    if targetjob_ref then
        jobs:add(targetjob_ref, rootjob)
    else
        local nodejob = jobs:add(nodeinfo.job, rootjob)
        if nodejob then
            jobrefs[nodeinfo.name] = nodejob
            for _, depname in ipairs(nodeinfo.deps) do
                local dep = nodes[depname]
                if dep then
                    _build_jobs_for_nodedeps(nodes, jobs, nodejob, jobrefs, dep)
                end
            end
        end
    end
end

-- build jobs
--
-- @param nodes     the node graph dependencies
-- @param jobs      the jobpool object
-- @param rootjob   the root job
--
-- @code
--[[
    nodes["node1"] = {
        name = "node1",
        deps = {"node2", "node3"},
        job = batchjobs:newjob("/job/node1", function(index, total)
        end)
    }
--]]
function main(nodes, jobs, rootjob)
    local depset = hashset.new()
    for _, nodeinfo in pairs(nodes) do
        assert(nodeinfo.job)
        for _, depname in ipairs(nodeinfo.deps) do
            depset:insert(depname)
        end
    end
    local nodes_root = {}
    for _, nodeinfo in pairs(nodes) do
        if not depset:has(nodeinfo.name) then
            table.insert(nodes_root, nodeinfo)
        end
    end
    local jobrefs = {}
    for _, nodeinfo in pairs(nodes_root) do
        _build_jobs_for_nodedeps(nodes, jobs, rootjob, jobrefs, nodeinfo)
    end
end
