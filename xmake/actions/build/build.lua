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
-- @file        build.lua
--

-- imports
import("core.base.option")
import("core.project.config")
import("core.project.project")
import("private.async.jobpool")
import("private.async.runjobs")
import("private.utils.batchcmds")
import("core.base.hashset")
import("private.service.client_config")
import("private.service.distcc_build.client", {alias = "distcc_build_client"})

-- clean target for rebuilding
function _clean_target(target)
    if target:targetfile() then
        os.tryrm(target:symbolfile())
        os.tryrm(target:targetfile())
    end
end

-- add builtin batch jobs
function _add_batchjobs_builtin(batchjobs, rootjob, target)

    -- uses the rules script?
    local job, job_leaf
    for _, r in irpairs(target:orderules()) do -- reverse rules order for batchjobs:addjob()
        local script = r:script("build")
        if script then
            if r:extraconf("build", "batch") then
                job, job_leaf = assert(script(target, batchjobs, {rootjob = job or rootjob}), "rule(%s):on_build(): no returned job!", r:name())
            else
                job = batchjobs:addjob("rule/" .. r:name() .. "/build", function (index, total)
                    script(target, {progress = (index * 100) / total})
                end, {rootjob = job or rootjob})
            end
        else
            local buildcmd = r:script("buildcmd")
            if buildcmd then
                job = batchjobs:addjob("rule/" .. r:name() .. "/build", function (index, total)
                    local batchcmds_ = batchcmds.new({target = target})
                    buildcmd(target, batchcmds_, {progress =  (index * 100) / total})
                    batchcmds_:runcmds({dryrun = option.get("dry-run")})
                end, {rootjob = job or rootjob})
            end
        end
    end

    -- uses the builtin target script
    if not job and (target:is_static() or target:is_binary() or target:is_shared() or target:is_object()) then
        job, job_leaf = import("kinds." .. target:kind(), {anonymous = true})(batchjobs, rootjob, target)
    end
    job = job or rootjob
    return job, job_leaf or job
end

-- add batch jobs
function _add_batchjobs(batchjobs, rootjob, target)

    local job, job_leaf
    local script = target:script("build")
    if not script then
        -- do builtin batch jobs
        job, job_leaf = _add_batchjobs_builtin(batchjobs, rootjob, target)
    elseif target:extraconf("build", "batch") then
        -- do custom batch script
        -- e.g.
        -- target("test")
        --     on_build(function (target, batchjobs, opt)
        --         return batchjobs:addjob("test", function (idx, total)
        --             print("build it")
        --         end, {rootjob = opt.rootjob})
        --     end, {batch = true})
        --
        job, job_leaf = assert(script(target, batchjobs, {rootjob = rootjob}), "target(%s):on_build(): no returned job!", target:name())
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
        end, {rootjob = rootjob})
    end
    return job, job_leaf or job
end

-- add batch jobs for the given target
function _add_batchjobs_for_target(batchjobs, rootjob, target)

    -- has been disabled?
    if not target:is_enabled() then
        return
    end

    -- add after_build job for target
    local oldenvs
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
            else
                local after_buildcmd = r:script("buildcmd_after")
                if after_buildcmd then
                    local batchcmds_ = batchcmds.new({target = target})
                    after_buildcmd(target, batchcmds_, {progress = progress})
                    batchcmds_:runcmds({dryrun = option.get("dry-run")})
                end
            end
        end

        -- restore environments
        if oldenvs then
            os.setenvs(oldenvs)
        end

    end, {rootjob = rootjob})

    -- add batch jobs for target, @note only on_build script support batch jobs
    local job_build, job_build_leaf = _add_batchjobs(batchjobs, job_after_build, target)

    -- add before_build job for target
    local job_build_before = batchjobs:addjob(target:name() .. "/before_build", function (index, total)

        -- enter package environments
        oldenvs = os.addenvs(target:pkgenvs())

        -- clean target if rebuild
        if option.get("rebuild") and not option.get("dry-run") then
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
            else
                local before_buildcmd = r:script("buildcmd_before")
                if before_buildcmd then
                    local batchcmds_ = batchcmds.new({target = target})
                    before_buildcmd(target, batchcmds_, {progress = progress})
                    batchcmds_:runcmds({dryrun = option.get("dry-run")})
                end
            end
        end
    end, {rootjob = job_build_leaf})

    -- we need do build_before after all dependent targets if across_targets_in_parallel is disabled
    return target:policy("build.across_targets_in_parallel") == false and job_build_before or job_build, job_after_build
end

-- add batch jobs for the given target and deps
function _add_batchjobs_for_target_and_deps(batchjobs, rootjob, jobrefs, target)
    local targetjob_ref = jobrefs[target:name()]
    if targetjob_ref then
        batchjobs:add(targetjob_ref, rootjob)
    else
        local targetjob, targetjob_root = _add_batchjobs_for_target(batchjobs, rootjob, target)
        if targetjob and targetjob_root then
            jobrefs[target:name()] = targetjob_root
            for _, depname in ipairs(target:get("deps")) do
                _add_batchjobs_for_target_and_deps(batchjobs, targetjob, jobrefs, project.target(depname))
            end
        end
    end
end

-- get batch jobs, @note we need export it for private.diagnosis.dump_buildjobs
function get_batchjobs(targetname, group_pattern)

    -- get root targets
    local targets_root = {}
    if targetname then
        table.insert(targets_root, project.target(targetname))
    else
        local depset = hashset.new()
        local targets = {}
        for _, target in pairs(project.targets()) do
            local group = target:get("group")
            if (target:is_default() and not group_pattern) or option.get("all") or (group_pattern and group and group:match(group_pattern)) then
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
    local jobrefs = {}
    local batchjobs = jobpool.new()
    for _, target in pairs(targets_root) do
        _add_batchjobs_for_target_and_deps(batchjobs, batchjobs:rootjob(), jobrefs, target)
    end
    return batchjobs
end

-- the main entry
function main(targetname, group_pattern)

    -- enable distcc?
    local distcc
    if distcc_build_client.is_connected() then
        client_config.load()
        distcc = distcc_build_client.singleton()
    end

    -- build all jobs
    local batchjobs = get_batchjobs(targetname, group_pattern)
    if batchjobs and batchjobs:size() > 0 then
        local curdir = os.curdir()
        runjobs("build", batchjobs, {on_exit = function (errors)
            import("utils.progress")
            if errors and progress.showing_without_scroll() then
                print("")
            end
        end, comax = option.get("jobs") or 1, curdir = curdir, count_as_index = true, distcc = distcc})
        os.cd(curdir)
    end
end


