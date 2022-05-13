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
-- @file        jobpool.lua
--

-- imports
import("core.base.object")
import("core.base.hashset")

-- define module
local jobpool = jobpool or object {_init = {"_size", "_rootjob", "_leafjobs", "_poprefs"}}

-- get jobs size
function jobpool:size()
    return self._size
end

-- get root job
function jobpool:rootjob()
    return self._rootjob
end

-- new run job
--
-- e.g.
-- local job = jobpool:newjob("xxx", function (index, total) end)
-- jobpool:add(job, rootjob1)
-- jobpool:add(job, rootjob2)
-- jobpool:add(job, rootjob3)
--
function jobpool:newjob(name, run, opt)
    opt = opt or {}
    return {name = name, run = run, distcc = opt.distcc}
end

-- add run job to the given job node
--
-- e.g.
-- local job = jobpool:addjob("xxx", function (index, total) end, {rootjob = rootjob})
--
-- @param name      the job name
-- @param run       the run command/script
-- @param opt       the options (rootjob, distcc)
--                  we can support distcc build if distcc is true
--
function jobpool:addjob(name, run, opt)
    opt = opt or {}
    return self:add({name = name, run = run, distcc = opt.distcc}, opt.rootjob)
end

-- add job to the given job node
--
-- @param job       the job
-- @param rootjob   the root job node (optional)
--
function jobpool:add(job, rootjob)

    -- add job to the root job
    rootjob = rootjob or self:rootjob()
    rootjob._deps = rootjob._deps or hashset.new()
    rootjob._deps:insert(job)

    -- attach parents node
    local parents = job._parents
    if not parents then
        parents = {}
        job._parents = parents
        self._size = self._size + 1 -- @note only update number for new job without parents
    end
    table.insert(parents, rootjob)

    -- in group? attach the group node
    local group = self._group
    if group then
        job._deps = job._deps or hashset.new()
        job._deps:insert(group)
        group._parents = group._parents or {}
        table.insert(group._parents, job)
    end
    return job
end

-- pop job without deps at leaf node
function jobpool:pop()

    -- no jobs?
    if self:size() == 0 then
        return
    end

    -- init leaf jobs first
    local leafjobs = self._leafjobs
    if #leafjobs == 0 then
        local refs = {}
        self:_genleafjobs(self:rootjob(), leafjobs, refs)
    end

    -- pop a job from the leaf jobs
    if #leafjobs > 0 then

        -- get job
        local job = leafjobs[#leafjobs]
        table.remove(leafjobs, #leafjobs)

        -- get priority and parents node
        local priority = job._priority or 0
        local parents = assert(job._parents, "invalid job without parents node!")

        -- update all parents nodes
        for _, p in ipairs(parents) do
            p._priority = math.max(p._priority or 0, priority + 1)
            p._deps:remove(job)
            if p._deps:empty() and self._size > 0 then
                table.insert(leafjobs, 1, p)
            end
        end

        -- is group node or referenced node (it has been popped once) ?
        local poprefs = self._poprefs
        local jobkey = tostring(job)
        if job.group or poprefs[jobkey] then
            -- pop the next real job
            return self:pop()
        else
            -- pop this job
            self._size = self._size - 1
            poprefs[jobkey] = true
            return job, priority
        end
    end
end

-- enter group
--
-- @param name      the group name
--
function jobpool:group_enter(name)
    assert(not self._group, "jobpool: cannot enter group(%s)!", name)
    self._group = {name = name, group = true}
end

-- leave group
--
-- @return          the group node
--
function jobpool:group_leave()
    local group = self._group
    self._group = nil
    if group and group._parents then
        return group
    end
end

-- generate all leaf jobs from the given job
function jobpool:_genleafjobs(job, leafjobs, refs)
    local deps = job._deps
    if deps and not deps:empty() then
        for _, dep in deps:keys() do
            local depkey = tostring(dep)
            if not refs[depkey] then
                refs[depkey] = true
                self:_genleafjobs(dep, leafjobs, refs)
            end
        end
    else
        table.insert(leafjobs, job)
    end
end

-- generate jobs tree for the given job
function jobpool:_gentree(job, refs)
    local tree = {job.group and ("group(" .. job.name .. ")") or job.name}
    local deps = job._deps
    if deps and not deps:empty() then
        for _, dep in deps:keys() do
            local depkey = tostring(dep)
            if refs[depkey] then
                local depname = dep.group and ("group(" .. dep.name .. ")") or dep.name
                table.insert(tree, "ref(" .. depname .. ")")
            else
                refs[depkey] = true
                table.insert(tree, self:_gentree(dep, refs))
            end
        end
    end
    -- strip tree
    local smalltree = hashset.new()
    for _, item in ipairs(tree) do
        item = table.unwrap(item)
        if smalltree:size() < 16 or type(item) == "table" then
            smalltree:insert(item)
        else
            smalltree:insert("...")
        end
    end
    return smalltree:to_array()
end

-- tostring
function jobpool:__tostring()
    local refs = {}
    return string.serialize(self:_gentree(self:rootjob(), refs), {indent = 2})
end

-- new a jobpool
function new()
    return jobpool {0, {name = "root"}, {}, {}}
end
