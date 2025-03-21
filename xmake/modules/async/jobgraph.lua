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
-- @file        jobgraph.lua
--

-- imports
import("core.base.object")
import("core.base.list")
import("core.base.graph")
import("core.base.hashset")

-- define module
local jobqueue = jobqueue or object {_init = {"_jobgraph", "_dag"}}
local jobgraph = jobgraph or object {_init = {"_name", "_jobs", "_size", "_dag", "_groups"}}

-- remove the finished job
function jobqueue:remove(job)
    local dag = self._dag
    dag:partial_topo_sort_remove(job)
end

-- get a free job from the job queue
function jobqueue:getfree()
    local dag = self._dag
    local freejob, has_cycle = dag:partial_topo_sort_next()
    if has_cycle then
        local names = {}
        local cycle = dag:find_cycle()
        if cycle then
            for _, job in ipairs(cycle) do
                table.insert(names, job.name)
            end
            table.insert(names, names[1])
        end
        raise("%s: circular job dependency detected!\n%s", self._jobgraph, table.concat(names, "\n   -> "))
    end
    return freejob
end

-- add a job to the jobgraph
--
-- e.g.
-- jobgraph:add("xxx", function (index, total, opt)
-- end)
--
-- @param name      the job name
-- @param run       the job run command/script
-- @param opt       the job options, e.g. {group = "xxx"}
--
function jobgraph:add(name, run, opt)
    local jobs = self._jobs
    if not jobs[name] then
        local job = {name = name, run = run, opt = opt}
        jobs[name] = job
        self._size = self._size + 1

        local group_name = opt.group
        if group_name then
            local groups = self._groups[group_name]
            if not groups then
                groups = {}
                self._groups[group_name] = groups
            end
            table.insert(groups, job)
        end
    end
end

-- remove a given job
function jobgraph:remove(name)
    local jobs = self._jobs
    local job = jobs[name]
    local dag = self._dag
    if job then
        assert(self._size > 0)
        jobs[name] = nil
        dag:remove_vertex(job)
        self._size = self._size - 1
    end
end

-- add job deps, e.g. add_deps(a, b, c, ...): a -> b -> c, ...
function jobgraph:add_deps(...)
    local prev
    local dag = self._dag
    local jobs = self._jobs
    for _, name in ipairs(table.pack(...)) do
        local curr = assert(jobs[name], "job(%s) not found in jobgraph(%s)", name, self)
        if prev then
            if not dag:has_edge(prev, curr) then
                dag:add_edge(prev, curr)
            end
        end
        prev = curr
    end
    -- TODO
    -- add groups jobs
end

-- build a job queue
function jobgraph:build()
    local dag = self._dag
    dag:partial_topo_sort_reset()
    return jobqueue {self, dag}
end

-- get jobs
function jobgraph:jobs()
    return self._jobs
end

-- get jobgraph name
function jobgraph:name()
    return self._name
end

-- get job size
function jobgraph:size()
    return self._size
end

-- tostring
function jobgraph:__tostring()
    return string.format("<jobgraph:%s/%d>", self:name() or "anonymous", self:size())
end

-- new a jobgraph
function new(name)
    return jobgraph {name, {}, 0, graph.new(true), {}}
end
