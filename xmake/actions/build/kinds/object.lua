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
import("private.async.runjobs")
import("private.utils.batchcmds")

-- get rule
function _get_rule(rulename)
    local ruleinst = assert(project.rule(rulename) or rule.rule(rulename), "unknown rule: %s", rulename)
    return ruleinst
end

-- get max depth of rule
function _get_rule_max_depth(ruleinst, depth)
    for _, depname in ipairs(ruleinst:get("deps")) do
        local dep = _get_rule(depname)
        local dep_depth = depth
        if ruleinst:extraconf("deps", depname, "order") then
            dep_depth = dep_depth + 1
        end
        return _get_rule_max_depth(dep, dep_depth)
    end
    return depth
end

-- add batch jobs for the custom rule
function _add_batchjobs_for_rule(batchjobs, rootjob, target, sourcebatch, suffix)

    -- get rule
    local rulename = assert(sourcebatch.rulename, "unknown rule for sourcebatch!")
    local ruleinst = _get_rule(rulename)

    -- add batch jobs for xx_build_files
    local scriptname = "build_files" .. (suffix and ("_" .. suffix) or "")
    local script = ruleinst:script(scriptname)
    if script then
        if ruleinst:extraconf(scriptname, "batch") then
            script(target, batchjobs, sourcebatch, {rootjob = rootjob, distcc = ruleinst:extraconf(scriptname, "distcc")})
        else
            batchjobs:addjob("rule/" .. rulename .. "/" .. scriptname, function (index, total)
                script(target, sourcebatch, {progress = (index * 100) / total})
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
                batchjobs:addjob(sourcefile, function (index, total)
                    script(target, sourcefile, {sourcekind = sourcekind, progress = (index * 100) / total})
                end, {rootjob = rootjob, distcc = ruleinst:extraconf(scriptname, "distcc")})
            end
        end
    end

    -- add batch jobs for xx_buildcmd_files
    if not script then
        scriptname = "buildcmd_files" .. (suffix and ("_" .. suffix) or "")
        script = ruleinst:script(scriptname)
        if script then
            batchjobs:addjob("rule/" .. rulename .. "/" .. scriptname, function (index, total)
                local batchcmds_ = batchcmds.new({target = target})
                local distcc = ruleinst:extraconf(scriptname, "distcc")
                script(target, batchcmds_, sourcebatch, {progress = (index * 100) / total, distcc = distcc})
                batchcmds_:runcmds({dryrun = option.get("dry-run")})
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
                batchjobs:addjob(sourcefile, function (index, total)
                    local batchcmds_ = batchcmds.new({target = target})
                    script(target, batchcmds_, sourcefile, {sourcekind = sourcekind, progress = (index * 100) / total})
                    batchcmds_:runcmds({dryrun = option.get("dry-run")})
                end, {rootjob = rootjob, distcc = ruleinst:extraconf(scriptname, "distcc")})
            end
        end
    end
end

-- add batch jobs for target
function _add_batchjobs_for_target(batchjobs, rootjob, target, sourcebatch, suffix)

    -- add batch jobs
    local scriptname = "build_files" .. (suffix and ("_" .. suffix) or "")
    local script = target:script(scriptname)
    if script then
        if target:extraconf(scriptname, "batch") then
            script(target, batchjobs, sourcebatch, {rootjob = rootjob, distcc = target:extraconf(scriptname, "distcc")})
        else
            batchjobs:addjob(target:name() .. "/" .. scriptname, function (index, total)
                script(target, sourcebatch, {progress = (index * 100) / total})
            end, {rootjob = rootjob})
        end
        return true
    else
        scriptname = "build_file" .. (suffix and ("_" .. suffix) or "")
        script = target:script(scriptname)
        if script then
            local sourcekind = sourcebatch.sourcekind
            for _, sourcefile in ipairs(sourcebatch.sourcefiles) do
                batchjobs:addjob(sourcefile, function (index, total)
                    script(target, sourcefile, {sourcekind = sourcekind, progress = (index * 100) / total})
                end, {rootjob = rootjob, distcc = target:extraconf(scriptname, "distcc")})
            end
            return true
        end
    end
end

-- add batch jobs for group
function _add_batchjobs_for_group(batchjobs, rootjob, target, group, suffix)
    local did_on_targets = _g.did_on_targets
    if not did_on_targets then
        did_on_targets = {}
        _g.did_on_targets = did_on_targets
    end
    for _, item in pairs(group) do
        local sourcebatch = item.sourcebatch
        if item.target then
            if _add_batchjobs_for_target(batchjobs, rootjob, target, sourcebatch, suffix) and not suffix then
                did_on_targets[sourcebatch] = true
            end
        end
        -- override on_xxx script in target? we need ignore rule scripts
        if item.rule and (suffix or not did_on_targets[sourcebatch]) then
            _add_batchjobs_for_rule(batchjobs, rootjob, target, sourcebatch, suffix)
        end
    end
end

-- build sourcebatch groups for target
function _build_sourcebatch_groups_for_target(groups, target, sourcebatches)
    local group = groups[1]
    for _, sourcebatch in pairs(sourcebatches) do
        local rulename = assert(sourcebatch.rulename, "unknown rule for sourcebatch!")
        local item = group[rulename] or {}
        item.target = target
        item.sourcebatch = sourcebatch
        group[rulename] = item
    end
end

-- build sourcebatch groups for rules
function _build_sourcebatch_groups_for_rules(groups, target, sourcebatches)
    for _, sourcebatch in pairs(sourcebatches) do
        local rulename = assert(sourcebatch.rulename, "unknown rule for sourcebatch!")
        local ruleinst = _get_rule(rulename)
        local depth = _get_rule_max_depth(ruleinst, 1)
        local group = groups[depth]
        if group == nil then
            group = {}
            groups[depth] = group
        end
        local item = group[rulename] or {}
        item.rule = ruleinst
        item.sourcebatch = sourcebatch
        group[rulename] = item
    end
end

-- build sourcebatch groups by rule dependencies order
function _build_sourcebatch_groups(target, sourcebatches)
    local groups = {{}}
    _build_sourcebatch_groups_for_target(groups, target, sourcebatches)
    _build_sourcebatch_groups_for_rules(groups, target, sourcebatches)
    if #groups > 0 then
        groups = table.reverse(groups)
    end
    return groups
end

-- add batch jobs for building source files
function add_batchjobs_for_sourcefiles(batchjobs, rootjob, target, sourcebatches)

    -- build sourcebatch groups first
    local groups = _build_sourcebatch_groups(target, sourcebatches)

    -- add batch jobs for build_after
    local groups_root = rootjob
    local groups_leaf = rootjob
    for idx, group in ipairs(groups) do
        batchjobs:group_enter(target:name() .. "/after_build_files" .. idx)
        _add_batchjobs_for_group(batchjobs, groups_leaf, target, group, "after")
        groups_leaf = batchjobs:group_leave() or groups_leaf
        if idx == 1 then
            groups_root = groups_leaf
        end
    end

    -- add batch jobs for build
    for idx, group in ipairs(groups) do
        batchjobs:group_enter(target:name() .. "/build_files" .. idx)
        _add_batchjobs_for_group(batchjobs, groups_leaf, target, group)
        groups_leaf = batchjobs:group_leave() or groups_leaf
    end

    -- add batch jobs for build_before
    for idx, group in ipairs(groups) do
        batchjobs:group_enter(target:name() .. "/before_build_files" .. idx)
        _add_batchjobs_for_group(batchjobs, groups_leaf, target, group, "before")
        groups_leaf = batchjobs:group_leave() or groups_leaf
    end
    return groups_leaf, groups_root
end

-- add batch jobs for building object files
function main(batchjobs, rootjob, target)
    return add_batchjobs_for_sourcefiles(batchjobs, rootjob, target, target:sourcebatches())
end

