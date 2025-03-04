--!A cross-platform scan utility based on Lua
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
-- @author      ruki, Arthapz
-- @file        scan.lua
--

import("core.base.option")
import("core.project.config")
import("core.project.project")
import("async.runjobs")
import("private.async.jobpool")
import("private.utils.batchcmds")
import("private.utils.rule_groups")
import("core.base.hashset")

-- has scripts for the custom rule
function _has_scripts_for_rule(ruleinst, suffix)

    -- add batch jobs for xx_scan_files
    local scriptname = "scan_files" .. (suffix and ("_" .. suffix) or "")
    local script = ruleinst:script(scriptname)
    if script then
        return true
    end

    -- add batch jobs for xx_scan_file
    scriptname = "scan_file" .. (suffix and ("_" .. suffix) or "")
    script = ruleinst:script(scriptname)
    if script then
        return true
    end

    -- add batch jobs for xx_scancmd_files
    scriptname = "scancmd_files" .. (suffix and ("_" .. suffix) or "")
    script = ruleinst:script(scriptname)
    if script then
        return true
    end

    -- add batch jobs for xx_scancmd_file
    scriptname = "scancmd_file" .. (suffix and ("_" .. suffix) or "")
    script = ruleinst:script(scriptname)
    if script then
        return true
    end
end

-- has scripts for target
function _has_scripts_for_target(target, suffix)
    local scriptname = "scan_files" .. (suffix and ("_" .. suffix) or "")
    local script = target:script(scriptname)
    if script then
        return true
    else
        scriptname = "scan_file" .. (suffix and ("_" .. suffix) or "")
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

    -- add batch jobs for xx_scan_files
    local scriptname = "scan_files" .. (suffix and ("_" .. suffix) or "")
    local script = ruleinst:script(scriptname)
    if script then
        if ruleinst:extraconf(scriptname, "batch") then
            script(target, batchjobs, sourcebatch, 
                {rootjob = rootjob, distcc = ruleinst:extraconf(scriptname, "distcc")})
        else
            batchjobs:addjob("rule/" .. rulename .. "/" .. scriptname, function (index, total, opt)
                script(target, sourcebatch, {progress = opt.progress})
            end, {rootjob = rootjob})
        end
    end

    -- add batch jobs for xx_scan_file
    if not script then
        scriptname = "scan_file" .. (suffix and ("_" .. suffix) or "")
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

    -- add batch jobs for xx_scancmd_files
    if not script then
        scriptname = "scancmd_files" .. (suffix and ("_" .. suffix) or "")
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

    -- add batch jobs for xx_scancmd_file
    if not script then
        scriptname = "scancmd_file" .. (suffix and ("_" .. suffix) or "")
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

    -- we just scan sourcebatch with on_scan_files scripts
    --
    -- for example, c++.scan and c++.scan.modules.scaner rules have same sourcefiles,
    -- but we just scan it for c++.scan
    --
    -- @see https://github.com/xmake-io/xmake/issues/3171
    --
    local rulename = sourcebatch.rulename
    if rulename then
        local ruleinst = rule_groups.get_rule(target, rulename)
        if not ruleinst:script("scan_file") and
            not ruleinst:script("scan_files") then
            return
        end
    end

    -- add batch jobs
    local scriptname = "scan_files" .. (suffix and ("_" .. suffix) or "")
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
        scriptname = "scan_file" .. (suffix and ("_" .. suffix) or "")
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
            _add_batchjobs_for_target2(batchjobs, rootjob, target, sourcebatch, suffix)
        end
        -- override on_xxx script in target? we need to ignore rule scripts
        if item.rule and (suffix or not _has_scripts_for_target(target, suffix)) then
            _add_batchjobs_for_rule(batchjobs, rootjob, target, sourcebatch, suffix)
        end
    end
end

-- add batch jobs for scaning source files
function add_batchjobs_for_sourcefiles(batchjobs, rootjob, target, sourcebatches)

    -- scan sourcebatch groups first
    local groups = rule_groups.build_sourcebatch_groups(target, sourcebatches)

    -- add batch jobs for scan_after
    local groups_root
    local groups_leaf = rootjob
    for idx, group in ipairs(groups) do
        if _has_scripts_for_group(group, "after") then
            batchjobs:group_enter(target:name() .. "/after_scan_files" .. idx)
            _add_batchjobs_for_group(batchjobs, groups_leaf, target, group, "after")
            groups_leaf = batchjobs:group_leave() or groups_leaf
            groups_root = groups_root or groups_leaf
        end
    end

    -- add batch jobs for scan
    for idx, group in ipairs(groups) do
        if _has_scripts_for_group(group) then
            batchjobs:group_enter(target:name() .. "/scan_files" .. idx)
            _add_batchjobs_for_group(batchjobs, groups_leaf, target, group, nil)
            groups_leaf = batchjobs:group_leave() or groups_leaf
            groups_root = groups_root or groups_leaf
        end
    end

    -- add batch jobs for scan_before
    for idx, group in ipairs(groups) do
        if _has_scripts_for_group(group, "before") then
            batchjobs:group_enter(target:name() .. "/before_scan_files" .. idx)
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


-- add builtin batch jobs
function _add_batchjobs_builtin(batchjobs, rootjob, target)

    -- uses the rules script?
    local job, job_leaf
    for _, r in irpairs(target:orderules()) do -- reverse rules order for batchjobs:addjob()
        local script = r:script("scan")
        if script then
            if r:extraconf("scan", "batch") then
                job, job_leaf = assert(script(target, batchjobs, {rootjob = job or rootjob}), "rule(%s):on_scan(): no returned job!", r:name())
            else
                job = batchjobs:addjob("rule/" .. r:name() .. "/scan", function (index, total, opt)
                    script(target, {progress = opt.progress})
                end, {rootjob = job or rootjob})
            end
        else
            local scancmd = r:script("scancmd")
            if scancmd then
                job = batchjobs:addjob("rule/" .. r:name() .. "/scan", function (index, total, opt)
                    local batchcmds_ = batchcmds.new({target = target})
                    scancmd(target, batchcmds_, {progress = opt.progress})
                    batchcmds_:runcmds({changed = target:is_rebuilt(), dryrun = option.get("dry-run")})
                end, {rootjob = job or rootjob})
            end
        end
    end
    -- uses the builtin target script
    if not job and (target:is_static() or target:is_binary() or target:is_shared() or target:is_object() or target:is_moduleonly()) then
        local job_objects = add_batchjobs_for_object(batchjobs, rootjob, target)
        job, job_leaf = target:policy("build.across_targets_in_parallel") == false and job_objects or job_link, job_objects
    end
    job = job or rootjob
    return job, job_leaf or job
end

-- add batch jobs
function _add_batchjobs(batchjobs, rootjob, target)

    local job, job_leaf
    local script = target:script("scan")
    if not script then
        -- do builtin batch jobs
        job, job_leaf = _add_batchjobs_builtin(batchjobs, rootjob, target)
    elseif target:extraconf("scan", "batch") then
        -- do custom batch script
        -- e.g.
        -- target("test")
        --     on_scan(function (target, batchjobs, opt)
        --         return batchjobs:addjob("test", function (idx, total)
        --             print("scan it")
        --         end, {rootjob = opt.rootjob})
        --     end, {batch = true})
        --
        job, job_leaf = assert(script(target, batchjobs, {rootjob = rootjob}), "target(%s):on_scan(): no returned job!", target:name())
    else
        -- do custom script directly
        -- e.g.
        --
        -- target("test")
        --     on_scan(function (target, opt)
        --         print("scan it")
        --     end)
        --
        job = batchjobs:addjob(target:name() .. "/scan", function (index, total, opt)
            script(target, {progress = opt.progress})
        end, {rootjob = rootjob})
    end
    return job, job_leaf or job
end

-- add batch jobs for target
function _add_batchjobs_for_target2(batchjobs, rootjob, target, sourcebatch, suffix)

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
        if not ruleinst:script("scan_file") and
            not ruleinst:script("scan_files") then
            return
        end
    end

    -- add batch jobs
    local scriptname = "scan_files" .. (suffix and ("_" .. suffix) or "")
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
        scriptname = "scan_file" .. (suffix and ("_" .. suffix) or "")
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

-- add batch jobs for the given target
function _add_batchjobs_for_target(batchjobs, rootjob, target)

    -- has been disabled?
    if not target:is_enabled() then
        return
    end

    -- add after_scan job for target
    local pkgenvs = _g.pkgenvs or {}
    _g.pkgenvs = pkgenvs
    local job_scan_after = batchjobs:addjob(target:name() .. "/after_scan", function (index, total, opt)

        -- do after_scan
        local progress = opt.progress
        local after_scan = target:script("scan_after")
        if after_scan then
            after_scan(target, {progress = progress})
        end
        for _, r in ipairs(target:orderules()) do
            local after_scan = r:script("scan_after")
            if after_scan then
                after_scan(target, {progress = progress})
            else
                local after_scancmd = r:script("scancmd_after")
                if after_scancmd then
                    local batchcmds_ = batchcmds.new({target = target})
                    after_scancmd(target, batchcmds_, {progress = progress})
                    batchcmds_:runcmds({changed = target:is_rebuilt(), dryrun = option.get("dry-run")})
                end
            end
        end

        -- restore environments
        if target:pkgenvs() then
            pkgenvs.oldenvs = pkgenvs.oldenvs or os.getenvs()
            pkgenvs.newenvs = pkgenvs.newenvs or {}
            pkgenvs.newenvs[target] = nil
            local newenvs = pkgenvs.oldenvs
            for _, envs in pairs(pkgenvs.newenvs) do
                newenvs = os.joinenvs(envs, newenvs)
            end
            os.setenvs(newenvs)
        end

    end, {rootjob = rootjob})

    -- add batch jobs for target, @note only on_scan script support batch jobs
    local job_scan, job_scan_leaf = _add_batchjobs(batchjobs, job_scan_after, target)

    -- add before_scan job for target
    local job_scan_before = batchjobs:addjob(target:name() .. "/before_scan", function (index, total, opt)

        -- enter package environments
        -- https://github.com/xmake-io/xmake/issues/4033
        --
        -- maybe mixing envs isn't a great solution,
        -- but it's the most efficient compromise compared to setting envs in every on_scan_file.
        --
        if target:pkgenvs() then
            pkgenvs.oldenvs = pkgenvs.oldenvs or os.getenvs()
            pkgenvs.newenvs = pkgenvs.newenvs or {}
            pkgenvs.newenvs[target] = target:pkgenvs()
            local newenvs = pkgenvs.oldenvs
            for _, envs in pairs(pkgenvs.newenvs) do
                newenvs = os.joinenvs(envs, newenvs)
            end
            os.setenvs(newenvs)
        end

        -- clean target if rescan
        if target:is_rebuilt() and not option.get("dry-run") then
            _clean_target(target)
        end

        -- do before_scan
        -- we cannot add batchjobs for this rule scripts, @see https://github.com/xmake-io/xmake/issues/2684
        local progress = opt.progress
        local before_scan = target:script("scan_before")
        if before_scan then
            before_scan(target, {progress = progress})
        end
        for _, r in ipairs(target:orderules()) do
            local before_scan = r:script("scan_before")
            if before_scan then
                before_scan(target, {progress = progress})
            else
                local before_scancmd = r:script("scancmd_before")
                if before_scancmd then
                    local batchcmds_ = batchcmds.new({target = target})
                    before_scancmd(target, batchcmds_, {progress = progress})
                    batchcmds_:runcmds({changed = target:is_rebuilt(), dryrun = option.get("dry-run")})
                end
            end
        end
    end, {rootjob = job_scan_leaf})
    return job_scan_before, job_scan, job_scan_after
end

-- add batch jobs for the given target and deps
function _add_batchjobs_for_target_and_deps(batchjobs, rootjob, target, jobrefs, jobrefs_before)
    local targetjob_ref = jobrefs[target:name()]
    if targetjob_ref then
        batchjobs:add(targetjob_ref, rootjob)
    else
        local job_scan_before, job_scan, job_scan_after = _add_batchjobs_for_target(batchjobs, rootjob, target)
        if job_scan_before and job_scan and job_scan_after then
            jobrefs[target:name()] = job_scan_after
            jobrefs_before[target:name()] = job_scan_before
            for _, depname in ipairs(target:get("deps")) do
                local dep = project.target(depname, {namespace = target:namespace()})
                local targetjob = job_scan
                -- @see https://github.com/xmake-io/xmake/discussions/2500
                if dep:policy("build.across_targets_in_parallel") == false then
                    targetjob = job_scan_before
                end
                _add_batchjobs_for_target_and_deps(batchjobs, targetjob, dep, jobrefs, jobrefs_before)
            end
        end
    end
end

function get_batchjobs(targetnames, group_pattern)

  -- get root targets
    local targets_root = {}
    if targetnames then
        for _, targetname in ipairs(table.wrap(targetnames)) do
            local target = project.target(targetname)
            if target then
                table.insert(targets_root, target)
                if option.get("rescan") then
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
            if option.get("rescan") then
                target:data_set("rebuilt", true)
            end
        end
    end

    -- generate batch jobs for default or all targets
    local jobrefs = {}
    local jobrefs_before = {}
    local batchjobs = jobpool.new()
    for _, target in ipairs(targets_root) do
        _add_batchjobs_for_target_and_deps(batchjobs, batchjobs:rootjob(), target,  jobrefs, jobrefs_before)
    end

    -- add fence jobs, @see https://github.com/xmake-io/xmake/issues/5003
    for _, target in ipairs(project.ordertargets()) do
        local target_job_before = jobrefs_before[target:name()]
        if target_job_before then
            for _, dep in ipairs(target:orderdeps()) do
                if dep:policy("build.fence") then
                    local fence_job = jobrefs[dep:name()]
                    if fence_job then
                        batchjobs:add(fence_job, target_job_before)
                    end
                end
            end
        end
    end

    return batchjobs
end

-- the main entry
function main(targetnames, group_pattern)
    local batchjobs = get_batchjobs(targetnames, group_pattern)
    if batchjobs and batchjobs:size() > 0 then
        local curdir = os.curdir()
        runjobs("scan", batchjobs, {on_exit = function (errors)
            import("utils.progress")
            if errors and progress.showing_without_scroll() then
                print("")
            end
        end, comax = option.get("jobs") or 1, curdir = curdir, distcc = distcc})
        os.cd(curdir)
    end
end
