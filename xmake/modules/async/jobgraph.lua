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

-- define module
local jobqueue = jobqueue or object {_init = {"_jobgraph"}}
local jobgraph = jobgraph or object {_init = {"_name", "_jobs", "_size", "_dag", "_dirty"}}

-- build the job queue
function jobqueue:_build()
    local graph = self._jobgraph
    local dag = graph._dag
    local queue = dag:topological_sort()
    for _, v in ipairs(queue) do
        print(v.name)
    end
end

-- update the job queue
function jobqueue:_update()
    local graph = self._jobgraph
    if graph._dirty then
        self:_build()
        graph._dirty = false
    end
end

-- remove the given job from the job queue
function jobqueue:remove(job)
end

-- get a free job from the job queue
function jobqueue:getfree()

    -- update the job queue first
    self:_update()
end

-- add a job to the jobgraph
--
-- e.g.
-- jobgraph:add("xxx", function (index, total, opt)
-- end)
--
-- @param name      the job name
-- @param run       the job run command/script
-- @param opt       the job options
--
function jobgraph:add(name, run, opt)
    local jobs = self._jobs
    if not jobs[name] then
        local job = {name = name, run = run, opt = opt}
        jobs[name] = job
        self._size = self._size + 1
        self._dirty = true
    end
end

-- remove a given job
function jobgraph:remove(name)
    local jobs = self._jobs
    if jobs[name] then
        assert(self._size > 0)
        jobs[name] = nil
        self._size = self._size - 1
        self._dirty = true
    end
end

-- add job deps, e.g. add_deps(a, b, c, ...): a -> b -> c, ...
function jobgraph:add_deps(...)
    local prev
    local dirty
    local dag = self._dag
    local jobs = self._jobs
    for _, name in ipairs(table.pack(...)) do
        local curr = assert(jobs[name], "job(%s) not found in jobgraph(%s)", name, self)
        if prev then
            dag:add_edge(prev, curr)
            dirty = true
        end
        prev = curr
    end
    if dirty then
        self._dirty = true
    end
end

-- add jog group
function jobgraph:add_group(name, callback)
    -- TODO
    self._dirty = true
end

-- build a job queue
function jobgraph:build()
    return jobqueue {self}
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
    return jobgraph {name, {}, 0, graph.new(true), false}
end
