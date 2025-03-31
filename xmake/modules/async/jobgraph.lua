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
::continue::
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
    -- if it's a fake job, we need to skip it and continue to get the next job
    if freejob and not freejob.run then
        dag:partial_topo_sort_remove(freejob)
        goto continue
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
-- @param opt       the job options, e.g. {groups = {"xxx"}}
--
function jobgraph:add(name, run, opt)
    opt = opt or {}
    local dag = self._dag
    local jobs = self._jobs
    if not jobs[name] then
        local job = {name = name, run = run, opt = opt}
        jobs[name] = job
        dag:add_vertex(job)
        self._size = self._size + 1

        if self._current_groups or opt.groups then
            local job_groups = table.join(self._current_groups or {}, opt.groups)
            for _, group_name in ipairs(job_groups) do
                local groups = self._groups[group_name]
                if not groups then
                    groups = {}
                    self._groups[group_name] = groups
                end
                table.insert(groups, job)
            end
        end
    else
        raise("job(%s): has already been added!", name)
    end
end

-- remove a given job
function jobgraph:remove(name)
    local dag = self._dag
    local jobs = self._jobs
    local job = jobs[name]
    if job then
        assert(self._size > 0)
        jobs[name] = nil
        dag:remove_vertex(job)
        self._size = self._size - 1
    end
end

-- enter group to add jobs
--
-- e.g.
-- jobgraph:group("foo", function ()
--     jobgraph:add("job1", function (index, total, opt)
--         TODO
--     end)
--     jobgraph:add("job2", function (index, total, opt)
--         TODO
--     end)
-- end)
function jobgraph:group(name, callback)
    local current_groups = self._current_groups
    if current_groups == nil then
        current_groups = {}
        self._current_groups = current_groups
    end
    table.insert(current_groups, name)
    callback()
    table.remove(current_groups)
end

-- add job orders, e.g. add_orders(a, b, c, ...): a -> b -> c, ...
--
-- and it supports nil, e.g add_orders("foo", nil, "bar", ...)
-- and it also supports to add orders list, e.g. add_orders(orders)
--
function jobgraph:add_orders(...)
    local prev
    local prev_is_group
    local dag = self._dag
    local jobs = self._jobs
    local groups = self._groups
    local orders = table.pack(...)
    local count = orders.n
    if count == 1 and type(orders[1]) == "table" then
        orders = orders[1]
        count = #orders
    end
    for i = 1, count do
        local name = orders[i]
        if name then
            local curr_is_group = false
            local curr = jobs[name]
            if not curr then
                curr = groups[name]
                curr_is_group = true
            end
            assert(curr, "job(%s) not found in jobgraph(%s)", name, self)
            if prev then
                if prev_is_group and curr_is_group then
                    -- we use a fake job as a node to bridge the two groups.
                    local fakejob = {}
                    for _, job in ipairs(prev) do
                        if not dag:has_edge(job, fakejob) then
                            dag:add_edge(job, fakejob)
                        end
                    end
                    for _, job in ipairs(curr) do
                        if not dag:has_edge(fakejob, job) then
                            dag:add_edge(fakejob, job)
                        end
                    end
                elseif curr_is_group then
                    for _, job in ipairs(curr) do
                        if not dag:has_edge(prev, job) then
                            dag:add_edge(prev, job)
                        end
                    end
                elseif prev_is_group then
                    for _, job in ipairs(prev) do
                        if not dag:has_edge(job, curr) then
                            dag:add_edge(job, curr)
                        end
                    end
                else
                    if not dag:has_edge(prev, curr) then
                        dag:add_edge(prev, curr)
                    end
                end
            end
            prev = curr
            prev_is_group = curr_is_group
        end
    end
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

-- is empty?
function jobgraph:empty()
    return self:size() == 0
end

-- tostring
function jobgraph:__tostring()
    return string.format("<jobgraph:%s/%d>", self:name() or "anonymous", self:size())
end

-- new a jobgraph
function new(name)
    return jobgraph {name, {}, 0, graph.new(true), {}}
end
