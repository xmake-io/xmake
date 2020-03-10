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

-- define module
local jobpool = jobpool or object {_init = {"_size", "_rootjob", "_leafjobs"}}

-- get jobs size
function jobpool:size()
    return self._size
end

-- get dependent jobs size of the given job
function jobpool:depsize(job)
    return job._deps and job._deps:size() or 0
end

-- get root job
function jobpool:rootjob()
    return self._rootjob
end

-- new job 
--
-- @param name      the job name
-- @param run       the run command/script
--
function jobpool:newjob(name, run)
    return {name = name, run = run}
end

-- new group
--
-- @param name      the group name
--
function jobpool:newgroup(name)
    return self:newjob(name)
end

-- add group to the given job node
--
-- @param name      the group name
-- @param rootjob   the root job node (optional)
--
function jobpool:addgroup(name, rootjob)
    return self:addjob(name, nil, rootjob)
end

-- add run job to the given job node
--
-- @param name      the job name
-- @param run       the run command/script
-- @param rootjob   the root job node (optional)
--
function jobpool:addjob(name, run, rootjob)
    rootjob = rootjob or self:rootjob()
    local job = {name = name, run = run, _parent = rootjob}
    rootjob._deps = rootjob._deps or dlist:new()
    rootjob._deps:push(job)
    self._size = self._size + 1
    return job
end

-- add job to the given job node
--
-- @param job       the job or group
-- @param rootjob   the root job node (optional)
--
function jobpool:add(job, rootjob)
    rootjob = rootjob or self:rootjob()
    rootjob._deps = rootjob._deps or dlist:new()
    rootjob._deps:push(job)
    job._parent = rootjob
    self._size = self._size + 1
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
        self:_genleafjobs(self:rootjob(), leafjobs)
    end

    -- pop a job from the leaf jobs
    if #leafjobs > 0 then

        -- update jobs size
        self._size = self._size - 1

        -- get job
        local job = leafjobs[#leafjobs]
        table.remove(leafjobs, #leafjobs)

        -- remove this job from the parent node
        local priority = job._priority or 0
        local parent = assert(job._parent, "invalid job without parent node!")
        parent._priority = math.max(parent._priority or 0, priority + 1)
        parent._deps:remove(job)
        if parent._deps:empty() and self._size > 0 then
            table.insert(leafjobs, 1, parent)
        end
        return job, priority
    end
end

-- generate all leaf jobs from the given job
function jobpool:_genleafjobs(job, leafjobs)
    local deps = job._deps
    if deps and not deps:empty() then
        for dep in deps:items() do
            self:_genleafjobs(dep, leafjobs)
        end
    else
        table.insert(leafjobs, job)
    end
end

-- generate jobs tree for the given job
function jobpool:_gentree(job)
    local tree = {job.name}
    local deps = job._deps
    if deps and not deps:empty() then
        for dep in deps:items() do
            table.insert(tree, self:_gentree(dep))
        end
    end
    return tree
end

-- tostring
function jobpool:__tostring()
    return string.serialize(self:_gentree(self:rootjob()), {indent = 2})
end

-- new a jobpool
function new()
    return jobpool {0, {name = "root"}, {}}
end
