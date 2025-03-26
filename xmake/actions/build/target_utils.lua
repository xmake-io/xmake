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
-- @file        target_utils.lua
--

-- imports
import("core.base.option")
import("core.base.hashset")
import("core.project.config")
import("core.project.project")
import("async.runjobs", {alias = "async_runjobs"})
import("async.jobgraph", {alias = "async_jobgraph"})
import("private.utils.batchcmds")

-- add stage jobs for the given target
-- stage: before, after or ""
function _add_stage_jobs_for_target(jobgraph, target, stage, opt)
    opt = opt or {}
    local job_kind = opt.job_kind
    local progress = opt.progress

    -- the group name, e.g. foo/after_prepare, bar/before_build
    local group_name = string.format("%s/%s_%s", target:fullname(), stage, job_kind)

    -- the script name, e.g. before/after_prepare, before/after_build
    local script_name = stage ~= "" and (job_kind .. "_" .. stage) or job_kind

    -- the command script name, e.g. before/after_preparecmd, before/after_buildcmd
    local scriptcmd_name = stage ~= "" and (job_kind .. "cmd_" .. stage) or (job_kind .. "cmd")

    -- TODO sort them
    local instances = {target}
    for _, r in ipairs(target:orderules()) do
        table.insert(instances, r)
    end

    -- call target and rules script
    local jobdeps = {}
    for _, instance in ipairs(instances) do
        local script = instance:script(script_name)
        if script then
            local jobname = string.format("%s/%s/%s", instance == target and "target" or "rule", instance:fullname(), script_name)
            jobgraph:add(jobname, function (index, total, opt)
                -- TODO bind target envs
                script(target, {progress = progress})
            end, {groups = group_name})
            table.insert(jobdeps, jobname)
        else
            local scriptcmd = instance:script(scriptcmd_name)
            if scriptcmd then
                local jobname = string.format("%s/%s/%s", instance == target and "target" or "rule", instance:fullname(), scriptcmd_name)
                jobgraph:add(jobname, function (index, total, opt)
                    -- TODO bind target envs
                    local batchcmds_ = batchcmds.new({target = target})
                    scriptcmd(target, batchcmds_, {progress = progress})
                    batchcmds_:runcmds({changed = target:is_rebuilt(), dryrun = option.get("dry-run")})
                end, {groups = group_name})
                table.insert(jobdeps, jobname)
            end
        end
    end

    -- add job deps
    jobgraph:add_deps(jobdeps)
end

-- add jobs for the given target
function _add_jobs_for_target(jobgraph, target, opt)
    opt = opt or {}
    if not target:is_enabled() then
        return
    end

    -- add group jobs for target, e.g. after_xxx -> (depend on) on_xxx -> before_xxx
    local group        = _add_stage_jobs_for_target(jobgraph, target, "", opt)
    local group_before = _add_stage_jobs_for_target(jobgraph, target, "before", opt)
    local group_after  = _add_stage_jobs_for_target(jobgraph, target, "after", opt)
    jobgraph:add_deps(group_after, group, group_before)
end

-- add jobs for the given target and deps
function _add_jobs_for_target_and_deps(jobgraph, target, targetrefs, opt)
    local targetname = target:fullname()
    if not targetrefs[targetname] then
        targetrefs[targetname] = target
        _add_jobs_for_target(jobgraph, target, opt)
        for _, depname in ipairs(target:get("deps")) do
            local dep = project.target(depname, {namespace = target:namespace()})
            _add_jobs_for_target_and_deps(jobgraph, dep, targetrefs, opt)
        end
    end
end

-- get jobs
function _get_jobs(targets_root, opt)
    local jobgraph = async_jobgraph.new()
    local targetrefs = {}
    for _, target in ipairs(targets_root) do
        _add_jobs_for_target_and_deps(jobgraph, target, targetrefs, opt)
    end
    return jobgraph
end

-- get all root targets
function get_root_targets(targetnames, opt)
    opt = opt or {}

    -- get root targets
    local targets_root = {}
    if targetnames then
        for _, targetname in ipairs(table.wrap(targetnames)) do
            local target = project.target(targetname)
            if target then
                table.insert(targets_root, target)
                if option.get("rebuild") then
                    target:data_set("rebuilt", true)
                    if not option.get("shallow") then
                        for _, dep in ipairs(target:orderdeps()) do
                            dep:data_set("rebuilt", true)
                        end
                    end
                end
            end
        end
    else
        local group_pattern = opt.group_pattern
        local depset = hashset.new()
        local targets = {}
        for _, target in ipairs(project.ordertargets()) do
            if target:is_enabled() then
                local group = target:get("group")
                if (target:is_default() and not group_pattern) or option.get("all") or (group_pattern and group and group:match(group_pattern)) then
                    for _, depname in ipairs(target:get("deps")) do
                        depset:insert(depname)
                    end
                    table.insert(targets, target)
                end
            end
        end
        for _, target in ipairs(targets) do
            if not depset:has(target:name()) then
                table.insert(targets_root, target)
            end
            if option.get("rebuild") then
                target:data_set("rebuilt", true)
            end
        end
    end
    return targets_root
end

function runjobs(targets_root, opt)
    opt = opt or {}
    local job_kind = opt.job_kind
    local jobgraph = _get_jobs(targets_root, opt)
    if jobgraph and not jobgraph:empty() then
        local curdir = os.curdir()
        async_runjobs(job_kind, jobgraph, {on_exit = function (errors)
            import("utils.progress")
            if errors and progress.showing_without_scroll() then
                print("")
            end
        end, comax = option.get("jobs") or 1, curdir = curdir})
        os.cd(curdir)
    end
end
