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
-- @file        build.lua
--

-- imports
import("core.base.option")
import("core.project.config")
import("core.project.project")
import("core.platform.environment")
import("private.async.jobpool")
import("private.async.runjobs")
import("core.base.hashset")

-- clean target for rebuilding
function _clean_target(target)
    if not target:isphony() then
        os.tryrm(target:symbolfile())
        os.tryrm(target:targetfile())
    end
end

-- add builtin batch jobs 
function _add_batchjobs_builtin(batchjobs, rootjob, target)

    -- uses the rules script?
    local job
    for _, r in irpairs(target:orderules()) do -- reverse rules order for batchjobs:addjob()
        local script = r:script("build")
        if script then
            if r:extraconf("build", "batch") then
                job = assert(script(target, batchjobs, {rootjob = job or rootjob}), "rule(%s):on_build(): no returned job!", r:name())
            else
                job = batchjobs:addjob("rule/" .. r:name() .. "/build", function (index, total)
                    script(target, {progress = (index * 100) / total})
                end, job or rootjob)
            end
        end
    end

    -- uses the builtin target script
    if not job and not target:isphony() then
        job = import("kinds." .. target:targetkind(), {anonymous = true})(batchjobs, rootjob, target)
    end
    return job or rootjob
end

-- add batch jobs
function _add_batchjobs(batchjobs, rootjob, target)

    local job
    local script = target:script("build")
    if not script then
        -- do builtin batch jobs
        job = _add_batchjobs_builtin(batchjobs, rootjob, target)
    elseif target:extraconf("build", "batch") then 
        -- do custom batch script
        -- e.g. 
        -- target("test")
        --     on_build(function (target, batchjobs, opt) 
        --         return batchjobs:addjob("test", function (idx, total)
        --             print("build it")
        --         end, opt.rootjob)
        --     end, {batch = true})
        --
        job = assert(script(target, batchjobs, {rootjob = rootjob}), "target(%s):on_build(): no returned job!", target:name())
    else
        -- do custom script directly
        -- e.g.
        --
        -- target("test")
        --     on_build(function (target, opt) 
        --         print("build it")
        --     end)
        --
        job = batchjobs:addjob(target:name() .. "/build", function (index, total)
            script(target, {progress = (index * 100) / total})
        end, rootjob)
    end
    return job
end

-- add batch jobs for the given target 
function _add_batchjobs_for_target(batchjobs, rootjob, target)

    -- has been disabled?
    if target:get("enabled") == false then
        return 
    end

    -- add after_build job for target
    local oldenvs = {}
    local job_after_build = batchjobs:addjob(target:name() .. "/after_build", function (index, total)

        -- do after_build
        local progress = (index * 100) / total
        local after_build = target:script("build_after")
        if after_build then
            after_build(target, {progress = progress})
        end
        for _, r in ipairs(target:orderules()) do
            local after_build = r:script("build_after")
            if after_build then
                after_build(target, {progress = progress})
            end
        end
     
        -- leave the environments of the target packages
        for name, values in pairs(oldenvs) do
            os.setenv(name, values)
        end
    end, rootjob)

    -- add batch jobs for target, @note only on_build script support batch jobs
    local job_build = _add_batchjobs(batchjobs, job_after_build, target)

    -- add before_build job for target
    local job_before_build = batchjobs:addjob(target:name() .. "/before_build", function (index, total)

        -- enter the environments of the target packages
        for name, values in pairs(target:pkgenvs()) do
            oldenvs[name] = os.getenv(name)
            os.addenv(name, unpack(values))
        end

        -- clean target if rebuild
        if option.get("rebuild") then
            _clean_target(target)
        end

        -- do before_build
        local progress = (index * 100) / total
        local before_build = target:script("build_before")
        if before_build then
            before_build(target, {progress = progress})
        end
        for _, r in ipairs(target:orderules()) do
            local before_build = r:script("build_before")
            if before_build then
                before_build(target, {progress = progress})
            end
        end
    end, job_build)
    return job_before_build, job_after_build
end

-- add batch jobs for the given target and deps
function _add_batchjobs_for_target_and_deps(batchjobs, rootjob, inserted, target)
    local targetjob = inserted[target:name()]
    if targetjob then
        batchjobs:add(targetjob, rootjob)
    else
        local targetjob_leaf, targetjob_root = _add_batchjobs_for_target(batchjobs, rootjob, target) 
        if targetjob_leaf and targetjob_root then
            inserted[target:name()] = targetjob_root
            for _, depname in ipairs(target:get("deps")) do
                _add_batchjobs_for_target_and_deps(batchjobs, targetjob_leaf, inserted, project.target(depname)) 
            end
        end
    end
end

-- get batch jobs, @note we need export it for private.diagnosis.dump_buildjobs
function get_batchjobs(targetname)

    -- get root targets
    local targets_root = {}
    if targetname then
        table.insert(targets_root, project.target(targetname))
    else
        local depset = hashset.new()
        local targets = {}
        for _, target in pairs(project.targets()) do
            local default = target:get("default")
            if default == nil or default == true or option.get("all") then
                for _, depname in ipairs(target:get("deps")) do
                    depset:insert(depname)
                end
                table.insert(targets, target)
            end
        end
        for _, target in pairs(targets) do
            if not depset:has(target:name()) then
                table.insert(targets_root, target)
            end
        end
    end

    -- generate batch jobs for default or all targets
    local inserted = {}
    local batchjobs = jobpool.new()
    for _, target in pairs(targets_root) do
        _add_batchjobs_for_target_and_deps(batchjobs, batchjobs:rootjob(), inserted, target)
    end
    return batchjobs
end

-- the main entry
function main(targetname)

    -- build all jobs
    local batchjobs = get_batchjobs(targetname)
    if batchjobs and batchjobs:size() > 0 then
        environment.enter("toolchains")
        runjobs("build", batchjobs, {comax = option.get("jobs") or 1})
        environment.leave("toolchains")
    end
end


