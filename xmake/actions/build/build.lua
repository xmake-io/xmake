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

-- do build the given target
function _do_build_target(target, opt)

    -- build target
    if not target:isphony() then
        import("kinds." .. target:targetkind()).build(target, opt)
    end
end

-- on build the given target
function _on_build_target(target, opt)

    -- build target with rules
    local done = false
    for _, r in ipairs(target:orderules()) do
        local on_build = r:script("build")
        if on_build then
            on_build(target, opt)
            done = true
        end
    end
    if done then return end

    -- do build
    _do_build_target(target, opt)
end

-- add build jobs for script
function _add_buildjob_for_script(buildjobs, rootjob, target, script_name, originjob)

    local job
    local script = target:script(script_name)
    if not script then
        -- do builtin original batch job
        assert(originjob, "target(%s):%s(): not found!", target:name(), script_name)
        job = buildjobs:addjob(originjob, rootjob)
    elseif target:extraconf(script_name, "batch") then 
        -- do custom batch script
        -- e.g. 
        -- target("test")
        --     on_build(function (target, batchjobs, opt) 
        --         return batchjobs:addjob("test", function (idx, total)
        --             print("build it")
        --         end, opt.rootjob)
        --     end, {batch = true})
        --
        job = assert(script(target, buildjobs, {rootjob = rootjob}), "target(%s):%s(): no returned job!", target:name(), script_name)
    else
        -- do custom script directly
        -- e.g.
        --
        -- target("test")
        --     on_build(function (target, opt) 
        --         print("build it")
        --     end)
        --
        job = buildjobs:addjob(target:name() .. "/" .. script_name, function (index, total)
            script(target, {progress = (index * 100) / total})
        end, rootjob)
    end
    return job
end

-- add build jobs for the given target 
function _add_buildjob_for_target(buildjobs, rootjob, target)

    -- has been disabled?
    if target:get("enabled") == false then
        return 
    end

    -- add after_build job for target
    local oldenvs = {}
    local job_after_build = buildjobs:addjob(target:name() .. "/after_build", function (index, total)

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

    -- add build job for target
    local job_build = _add_buildjob_for_script(buildjobs, job_after_build, target, "build")

    -- add before_build job for target
    local job_before_build = buildjobs:addjob(target:name() .. "/before_build", function (index, total)

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
    return job_before_build
end

-- add build jobs for the given target and deps
function _add_buildjob_for_target_and_deps(buildjobs, rootjob, inserted, target)
    if not inserted[target:name()] then
        rootjob = _add_buildjob_for_target(buildjobs, rootjob, target)
        for _, depname in ipairs(target:get("deps")) do
            _add_buildjob_for_target_and_deps(buildjobs, rootjob, inserted, project.target(depname)) 
        end
        inserted[target:name()] = true
    end
end

-- get build jobs 
function _get_buildjobs(targetname)

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
                    table.insert(targets, target)
                end
            end
        end
        for _, target in pairs(targets) do
            if not depset:has(target:name()) then
                table.insert(targets_root, target)
            end
        end
    end

    -- generate build jobs for default or all targets
    local inserted = {}
    local buildjobs = jobpool.new()
    for _, target in pairs(targets_root) do
        _add_buildjob_for_target_and_deps(buildjobs, buildjobs:rootjob(), inserted, target)
    end
    return buildjobs
end

-- the main entry
function main(targetname)

    -- build all jobs
    local buildjobs = _get_buildjobs(targetname)
    print(buildjobs)
    if buildjobs and buildjobs:count() > 0 then
        environment.enter("toolchains")
        runjobs("build", buildjobs, {comax = option.get("jobs") or 1})
        environment.leave("toolchains")
    end
end


