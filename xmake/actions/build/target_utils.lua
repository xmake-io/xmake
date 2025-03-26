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

-- add jobs for the given target
function _add_jobs_for_target(jobgraph, target, opt)
    opt = opt or {}
    if not target:is_enabled() then
        return
    end

    -- add after_xxx jobs for target
    local job_kind = opt.job_kind
    local job_after = target:fullname() .. "/after_" .. job_kind
    --[[
    jobgraph:add(job_after, function (index, total, opt)
        local progress = opt.progress
        local script_aftername = job_kind .. "_after"
        local script_after = target:script(script_aftername)
        if script_after then
            script_after(target, {progress = progress})
        end
        for _, r in ipairs(target:orderules()) do
            local script_after = r:script(script_aftername)
            if script_after then
                script_after(target, {progress = progress})
            else
                local scriptcmd_aftername = job_kind .. "cmd_after"
                local scriptcmd_after = r:script(scriptcmd_aftername)
                if scriptcmd_after then
                    local batchcmds_ = batchcmds.new({target = target})
                    scriptcmd_after(target, batchcmds_, {progress = progress})
                    batchcmds_:runcmds({changed = target:is_rebuilt(), dryrun = option.get("dry-run")})
                end
            end
        end
    end)]]
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
