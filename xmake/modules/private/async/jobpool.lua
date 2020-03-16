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
-- @file        jobpool.lua
--

-- imports
import("core.base.dlist")
import("core.base.object")
import("core.base.hashset")

-- define module
local jobpool = jobpool or object {_init = {"_size", "_rootjob", "_leafjobs"}}

-- get jobs size
function jobpool:size()
    return self._size
end

-- get root job
function jobpool:rootjob()
    return self._rootjob
end

-- add run job to the given job node
--
-- @param name      the job name
-- @param run       the run command/script
-- @param rootjob   the root job node (optional)
--
function jobpool:addjob(name, run, rootjob)
    
    -- add job to the root job
    rootjob = rootjob or self:rootjob()
    local job = {name = name, run = run, _parent = rootjob}
    rootjob._deps = rootjob._deps or dlist:new()
    rootjob._deps:push(job)
    self._size = self._size + 1

    -- in group? attach the group node
    local group = self._group
    if group then
        job._deps = job._deps or dlist:new()
        job._deps:push(group)
        group._parent = group._parent or {}
        table.insert(group._parent, job)
    end
    return job
end

-- pop job without deps at leaf node 
function jobpool:popjob()

    -- no jobs?
    if self:size() == 0 then
        return 
    end

    -- init leaf jobs first
    local leafjobs = self._leafjobs
    if #leafjobs == 0 then
        local groups = {}
        self:_genleafjobs(self:rootjob(), leafjobs, groups)
    end

    -- pop a job from the leaf jobs
    if #leafjobs > 0 then

        -- get job
        local job = leafjobs[#leafjobs]
        table.remove(leafjobs, #leafjobs)

        -- get priority and parent node
        local priority = job._priority or 0
        local parent = assert(job._parent, "invalid job without parent node!")

        -- is group node? remove it from all parent jobs
        if job.group then
            for _, p in ipairs(parent) do
                p._priority = math.max(p._priority or 0, priority + 1)
                p._deps:remove(job)
                if p._deps:empty() and self._size > 0 then
                    table.insert(leafjobs, 1, p)
                end
            end
            return self:popjob()
        else

            -- update jobs size
            self._size = self._size - 1

            -- remove this job from the parent job
            parent._priority = math.max(parent._priority or 0, priority + 1)
            parent._deps:remove(job)
            if parent._deps:empty() and self._size > 0 then
                table.insert(leafjobs, 1, parent)
            end
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
    if group and group._parent then
        return group
    end
end

-- generate all leaf jobs from the given job
function jobpool:_genleafjobs(job, leafjobs, groups)
    local deps = job._deps
    if deps and not deps:empty() then
        for dep in deps:items() do
            if dep.group then
                if not groups[dep.name] then
                    groups[dep.name] = true
                    self:_genleafjobs(dep, leafjobs, groups)
                end
            else
                self:_genleafjobs(dep, leafjobs, groups)
            end
        end
    else
        table.insert(leafjobs, job)
    end
end

-- generate jobs tree for the given job
function jobpool:_gentree(job, groups)
    local tree = {job.group and ("group(" .. job.name .. ")") or job.name}
    local deps = job._deps
    if deps and not deps:empty() then
        for dep in deps:items() do
            if dep.group then
                if not groups[dep.name] then
                    groups[dep.name] = true
                    table.insert(tree, self:_gentree(dep, groups))
                end
            else
                table.insert(tree, self:_gentree(dep, groups))
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
    local groups = {}
    return string.serialize(self:_gentree(self:rootjob(), groups), {indent = 2})
end

-- new a jobpool
function new()
    return jobpool {0, {name = "root"}, {}}
end
