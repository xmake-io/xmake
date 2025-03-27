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
-- @file        object.lua
--

-- imports
import("core.base.option")
import("core.project.rule")
import("core.project.config")
import("core.project.project")
import("async.runjobs")
import("private.utils.batchcmds")
import("private.utils.rule_groups")

-- has scripts for the custom rule
function _has_scripts_for_rule(ruleinst, suffix)

    -- add batch jobs for xx_build_files
    local scriptname = "build_files" .. (suffix and ("_" .. suffix) or "")
    local script = ruleinst:script(scriptname)
    if script then
        return true
    end

    -- add batch jobs for xx_build_file
    scriptname = "build_file" .. (suffix and ("_" .. suffix) or "")
    script = ruleinst:script(scriptname)
    if script then
        return true
    end

    -- add batch jobs for xx_buildcmd_files
    scriptname = "buildcmd_files" .. (suffix and ("_" .. suffix) or "")
    script = ruleinst:script(scriptname)
    if script then
        return true
    end

    -- add batch jobs for xx_buildcmd_file
    scriptname = "buildcmd_file" .. (suffix and ("_" .. suffix) or "")
    script = ruleinst:script(scriptname)
    if script then
        return true
    end
end

-- has scripts for target
function _has_scripts_for_target(target, suffix)
    local scriptname = "build_files" .. (suffix and ("_" .. suffix) or "")
    local script = target:script(scriptname)
    if script then
        return true
    else
        scriptname = "build_file" .. (suffix and ("_" .. suffix) or "")
        script = target:script(scriptname)
        if script then
            return true
        end
    end
end

-- has scripts for group
function _has_scripts_for_group(group, suffix)
    for _, item in pairs(group) do
        if item.target and _has_scripts_for_target(item.target, suffix) then
            return true
        end
        if item.rule and _has_scripts_for_rule(item.rule, suffix) then
            return true
        end
    end
end

-- add batch jobs for the custom rule
function _add_batchjobs_for_rule(batchjobs, rootjob, target, sourcebatch, suffix)

    -- get rule
    local rulename = assert(sourcebatch.rulename, "unknown rule for sourcebatch!")
    local ruleinst = rule_groups.get_rule(target, rulename)

    -- add batch jobs for xx_build_files
    local scriptname = "build_files" .. (suffix and ("_" .. suffix) or "")
    local script = ruleinst:script(scriptname)
    if script then
        if ruleinst:extraconf(scriptname, "batch") then
            script(target, batchjobs, sourcebatch, {rootjob = rootjob, distcc = ruleinst:extraconf(scriptname, "distcc")})
        else
            batchjobs:addjob("rule/" .. rulename .. "/" .. scriptname, function (index, total, opt)
                script(target, sourcebatch, {progress = opt.progress})
            end, {rootjob = rootjob})
        end
    end

    -- add batch jobs for xx_build_file
    if not script then
        scriptname = "build_file" .. (suffix and ("_" .. suffix) or "")
        script = ruleinst:script(scriptname)
        if script then
            local sourcekind = sourcebatch.sourcekind
            for _, sourcefile in ipairs(sourcebatch.sourcefiles) do
                batchjobs:addjob(sourcefile, function (index, total, opt)
                    script(target, sourcefile, {sourcekind = sourcekind, progress = opt.progress})
                end, {rootjob = rootjob, distcc = ruleinst:extraconf(scriptname, "distcc")})
            end
        end
    end

    -- add batch jobs for xx_buildcmd_files
    if not script then
        scriptname = "buildcmd_files" .. (suffix and ("_" .. suffix) or "")
        script = ruleinst:script(scriptname)
        if script then
            batchjobs:addjob("rule/" .. rulename .. "/" .. scriptname, function (index, total, opt)
                local batchcmds_ = batchcmds.new({target = target})
                local distcc = ruleinst:extraconf(scriptname, "distcc")
                script(target, batchcmds_, sourcebatch, {progress = opt.progress, distcc = distcc})
                batchcmds_:runcmds({changed = target:is_rebuilt(), dryrun = option.get("dry-run")})
            end, {rootjob = rootjob})
        end
    end

    -- add batch jobs for xx_buildcmd_file
    if not script then
        scriptname = "buildcmd_file" .. (suffix and ("_" .. suffix) or "")
        script = ruleinst:script(scriptname)
        if script then
            local sourcekind = sourcebatch.sourcekind
            for _, sourcefile in ipairs(sourcebatch.sourcefiles) do
                batchjobs:addjob(sourcefile, function (index, total, opt)
                    local batchcmds_ = batchcmds.new({target = target})
                    script(target, batchcmds_, sourcefile, {sourcekind = sourcekind, progress = opt.progress})
                    batchcmds_:runcmds({changed = target:is_rebuilt(), dryrun = option.get("dry-run")})
                end, {rootjob = rootjob, distcc = ruleinst:extraconf(scriptname, "distcc")})
            end
        end
    end
end

-- add batch jobs for target
function _add_batchjobs_for_target(batchjobs, rootjob, target, sourcebatch, suffix)

    -- we just build sourcebatch with on_build_files scripts
    --
    -- for example, c++.build and c++.build.modules.builder rules have same sourcefiles,
    -- but we just build it for c++.build
    --
    -- @see https://github.com/xmake-io/xmake/issues/3171
    --
    local rulename = sourcebatch.rulename
    if rulename then
        local ruleinst = rule_groups.get_rule(target, rulename)
        if not ruleinst:script("build_file") and
            not ruleinst:script("build_files") then
            return
        end
    end

    -- add batch jobs
    local scriptname = "build_files" .. (suffix and ("_" .. suffix) or "")
    local script = target:script(scriptname)
    if script then
        if target:extraconf(scriptname, "batch") then
            script(target, batchjobs, sourcebatch, {rootjob = rootjob, distcc = target:extraconf(scriptname, "distcc")})
        else
            batchjobs:addjob(target:name() .. "/" .. scriptname, function (index, total, opt)
                script(target, sourcebatch, {progress = opt.progress})
            end, {rootjob = rootjob})
        end
        return true
    else
        scriptname = "build_file" .. (suffix and ("_" .. suffix) or "")
        script = target:script(scriptname)
        if script then
            local sourcekind = sourcebatch.sourcekind
            for _, sourcefile in ipairs(sourcebatch.sourcefiles) do
                batchjobs:addjob(sourcefile, function (index, total, opt)
                    script(target, sourcefile, {sourcekind = sourcekind, progress = opt.progress})
                end, {rootjob = rootjob, distcc = target:extraconf(scriptname, "distcc")})
            end
            return true
        end
    end
end

-- add batch jobs for group
function _add_batchjobs_for_group(batchjobs, rootjob, target, group, suffix)
    for _, item in pairs(group) do
        local sourcebatch = item.sourcebatch
        if item.target then
            _add_batchjobs_for_target(batchjobs, rootjob, target, sourcebatch, suffix)
        end
        -- override on_xxx script in target? we need to ignore rule scripts
        if item.rule and (suffix or not _has_scripts_for_target(target, suffix)) then
            _add_batchjobs_for_rule(batchjobs, rootjob, target, sourcebatch, suffix)
        end
    end
end

-- add batch jobs for building source files
function add_batchjobs_for_sourcefiles(batchjobs, rootjob, target, sourcebatches)

    -- build sourcebatch groups first
    local groups = rule_groups.build_sourcebatch_groups(target, sourcebatches)

    -- add batch jobs for build_after
    local groups_root
    local groups_leaf = rootjob
    for idx, group in ipairs(groups) do
        if _has_scripts_for_group(group, "after") then
            batchjobs:group_enter(target:name() .. "/after_build_files" .. idx)
            _add_batchjobs_for_group(batchjobs, groups_leaf, target, group, "after")
            groups_leaf = batchjobs:group_leave() or groups_leaf
            groups_root = groups_root or groups_leaf
        end
    end

    -- add batch jobs for build
    for idx, group in ipairs(groups) do
        if _has_scripts_for_group(group) then
            batchjobs:group_enter(target:name() .. "/build_files" .. idx)
            _add_batchjobs_for_group(batchjobs, groups_leaf, target, group)
            groups_leaf = batchjobs:group_leave() or groups_leaf
            groups_root = groups_root or groups_leaf
        end
    end

    -- add batch jobs for build_before
    for idx, group in ipairs(groups) do
        if _has_scripts_for_group(group, "before") then
            batchjobs:group_enter(target:name() .. "/before_build_files" .. idx)
            _add_batchjobs_for_group(batchjobs, groups_leaf, target, group, "before")
            groups_leaf = batchjobs:group_leave() or groups_leaf
            groups_root = groups_root or groups_leaf
        end
    end
    return groups_leaf, groups_root or groups_leaf
end

-- add batch jobs for building object files
function add_batchjobs_for_object(batchjobs, rootjob, target)
    return add_batchjobs_for_sourcefiles(batchjobs, rootjob, target, target:sourcebatches())
end

-- add batch jobs for building object target
function main(batchjobs, rootjob, target)

    -- add a fake link job
    local job_link = batchjobs:addjob(target:name() .. "/fakelink", function (index, total, opt)
    end, {rootjob = rootjob})

    -- we only need to return and depend the link job for each target,
    -- so we can compile the source files for each target in parallel
    --
    -- unless call set_policy("build.across_targets_in_parallel", false) to disable to build across targets in parallel.
    --
    local job_objects = add_batchjobs_for_object(batchjobs, job_link, target)
    return target:policy("build.across_targets_in_parallel") == false and job_objects or job_link, job_objects
end
