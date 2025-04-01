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
import("core.project.rule")
import("core.project.config")
import("core.project.project")
import("async.runjobs", {alias = "async_runjobs"})
import("async.jobgraph", {alias = "async_jobgraph"})
import("private.utils.batchcmds")

-- get rule
-- @note we need to get rule from target first, because we maybe will inject and replace builtin rule in target
function _get_rule(target, rulename)
    local ruleinst = assert(target:rule(rulename) or project.rule(rulename, {namespace = target:namespace()}) or
        rule.rule(rulename), "unknown rule: %s", rulename)
    return ruleinst
end

-- clean target for rebuilding
function _clean_target(target)
    if target:targetfile() then
        os.tryrm(target:symbolfile())
        os.tryrm(target:targetfile())
    end
end

-- match source files
function _match_sourcefiles(sourcefile, filepatterns)
    for _, filepattern in ipairs(filepatterns) do
        if sourcefile:match(filepattern.pattern) == sourcefile then
            if filepattern.excludes then
                if filepattern.rootdir and sourcefile:startswith(filepattern.rootdir) then
                    sourcefile = sourcefile:sub(#filepattern.rootdir + 2)
                end
                for _, exclude in ipairs(filepattern.excludes) do
                    if sourcefile:match(exclude) == sourcefile then
                        return false
                    end
                end
            end
            return true
        end
    end
end

-- match sourcebatches
function _match_sourcebatches(target, filepatterns)
    local newbatches = {}
    local sourcecount = 0
    for rulename, sourcebatch in pairs(target:sourcebatches()) do
        local objectfiles = sourcebatch.objectfiles
        local dependfiles = sourcebatch.dependfiles
        local sourcekind  = sourcebatch.sourcekind
        for idx, sourcefile in ipairs(sourcebatch.sourcefiles) do
            if _match_sourcefiles(sourcefile, filepatterns) then
                local newbatch = newbatches[rulename]
                if not newbatch then
                    newbatch             = {}
                    newbatch.sourcekind  = sourcekind
                    newbatch.rulename    = rulename
                    newbatch.sourcefiles = {}
                end
                table.insert(newbatch.sourcefiles, sourcefile)
                if objectfiles then
                    newbatch.objectfiles = newbatch.objectfiles or {}
                    table.insert(newbatch.objectfiles, objectfiles[idx])
                end
                if dependfiles then
                    newbatch.dependfiles = newbatch.dependfiles or {}
                    table.insert(newbatch.dependfiles, dependfiles[idx])
                end
                newbatches[rulename] = newbatch
                sourcecount = sourcecount + 1
            end
        end
    end
    if sourcecount > 0 then
        return newbatches
    end
end

-- add target jobs for the builtin script
function add_targetjobs_for_builtin_script(jobgraph, target, job_kind)
    if target:is_static() or target:is_binary() or target:is_shared() or target:is_object() or target:is_moduleonly() then
        if job_kind == "prepare" then
            import("builtin.prepare_files", {anonymous = true})(jobgraph, target)
        elseif job_kind == "link" then
            import("builtin.link_objects", {anonymous = true})(jobgraph, target)
        else
            import("builtin.build_" .. target:kind(), {anonymous = true})(jobgraph, target)
        end
    end
end

-- add target jobs for the given script
function add_targetjobs_for_script(jobgraph, target, instance, opt)
    opt = opt or {}
    local has_script = false

    -- call script
    if not has_script then
        local script_name = opt.script_name
        local script = instance:script(script_name)
        if script then
            -- call custom script with jobgraph
            -- e.g.
            --
            -- target("test")
            --     on_build(function (target, jobgraph, opt)
            --     end, {jobgraph = true})
            if instance:extraconf(script_name, "jobgraph") then
                script(target, jobgraph)
            elseif instance:extraconf(script_name, "batch") then
                wprint("%s.%s: the batch mode is deprecated, please use jobgraph mode instead of it, or disable `build.jobgraph` policy to use it.", instance:fullname(), script_name)
            else
                -- call custom script directly
                -- e.g.
                --
                -- target("test")
                --     on_build(function (target, opt)
                --     end)
                local jobname = string.format("%s/%s/%s", target:fullname(), instance:fullname(), script_name)
                jobgraph:add(jobname, function (index, total, opt)
                    script(target, {progress = opt.progress})
                end)
            end
            has_script = true
        end
    end

    -- call command script
    -- e.g.
    --
    -- target("test")
    --     on_buildcmd(function (target, batchcmds, opt)
    --     end)
    if not has_script then
        local scriptcmd_name = opt.scriptcmd_name
        local scriptcmd = instance:script(scriptcmd_name)
        if scriptcmd then
            local jobname = string.format("%s/%s/%s", target:fullname(), instance:fullname(), scriptcmd_name)
            jobgraph:add(jobname, function (index, total, opt)
                local batchcmds_ = batchcmds.new({target = target})
                scriptcmd(target, batchcmds_, {progress = opt.progress})
                batchcmds_:runcmds({changed = target:is_rebuilt(), dryrun = option.get("dry-run")})
            end)
            has_script = true
        end
    end
    return has_script
end

-- add target jobs with the given stage
-- stage: before, after or ""
function add_targetjobs_with_stage(jobgraph, target, stage, opt)
    opt = opt or {}
    local job_kind = opt.job_kind

    -- the group name, e.g. foo/after_prepare, bar/before_build
    local group_name = string.format("%s/%s_%s", target:fullname(), stage, job_kind)

    -- the script name, e.g. before/after_prepare, before/after_build
    local script_name = stage ~= "" and (job_kind .. "_" .. stage) or job_kind

    -- the command script name, e.g. before/after_preparecmd, before/after_buildcmd
    local scriptcmd_name = stage ~= "" and (job_kind .. "cmd_" .. stage) or (job_kind .. "cmd")

    -- TODO sort rules and jobs
    local instances = {target}
    for _, r in ipairs(target:orderules()) do
        table.insert(instances, r)
    end

    -- call target and rules script
    local jobsize = jobgraph:size()
    jobgraph:group(group_name, function ()
        local has_script = false
        local script_opt = {
            script_name = script_name,
            scriptcmd_name = scriptcmd_name
        }
        for _, instance in ipairs(instances) do
            if add_targetjobs_for_script(jobgraph, target, instance, script_opt) then
                has_script = true
            end
            -- if custom target.on_build/prepare exists, we need to ignore all scripts in rules
            if has_script and instance == target and stage == "" then
                break
            end
        end

        -- call builtin script, e.g. on_prepare, on_build, ...
        if not has_script and stage == "" then
            add_targetjobs_for_builtin_script(jobgraph, target, job_kind)
        end
    end)

    if jobgraph:size() > jobsize then
        return group_name
    end
end

-- add target jobs for the given target
function add_targetjobs(jobgraph, target, opt)
    opt = opt or {}
    if not target:is_enabled() then
        return
    end

    local pkgenvs = _g.pkgenvs
    if pkgenvs == nil then
        pkgenvs = {}
        _g.pkgenvs = pkgenvs
    end

    local job_kind = opt.job_kind
    local job_begin = string.format("target/%s/begin_%s", target:fullname(), job_kind)
    local job_end = string.format("target/%s/end_%s", target:fullname(), job_kind)
    jobgraph:add(job_begin, function (index, total, opt)
        -- enter package environments
        -- https://github.com/xmake-io/xmake/issues/4033
        --
        -- maybe mixing envs isn't a great solution,
        -- but it's the most efficient compromise compared to setting envs in every on_build_file.
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

        -- clean target first if rebuild
        if job_kind == "prepare" and target:is_rebuilt() and not option.get("dry-run") then
            _clean_target(target)
        end
    end)

    jobgraph:add(job_end, function (index, total, opt)
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
    end)

    -- add jobs with target stage, e.g. begin -> before_xxx -> on_xxx -> after_xxx
    local group        = add_targetjobs_with_stage(jobgraph, target, "", opt)
    local group_before = add_targetjobs_with_stage(jobgraph, target, "before", opt)
    local group_after  = add_targetjobs_with_stage(jobgraph, target, "after", opt)
    jobgraph:add_orders(job_begin, group_before, group, group_after, job_end)
end

-- add target jobs for the given target and deps
function add_targetjobs_and_deps(jobgraph, target, targetrefs, opt)
    local targetname = target:fullname()
    if not targetrefs[targetname] then
        targetrefs[targetname] = target
        add_targetjobs(jobgraph, target, opt)
        for _, depname in ipairs(target:get("deps")) do
            local dep = project.target(depname, {namespace = target:namespace()})
            add_targetjobs_and_deps(jobgraph, dep, targetrefs, opt)
        end
    end
end

-- get target jobs
function get_targetjobs(targets_root, opt)
    local jobgraph = async_jobgraph.new(opt.job_kind)
    local targetrefs = {}
    for _, target in ipairs(targets_root) do
        add_targetjobs_and_deps(jobgraph, target, targetrefs, opt)
    end
    return jobgraph
end

-- add file jobs for the given script
function add_filejobs_for_script(jobgraph, target, instance, sourcebatch, opt)
    opt = opt or {}
    local has_script = false
    local job_prefix = target:fullname()
    local file_group = sourcebatch.rulename
    if target == instance then
        job_prefix = job_prefix .. "/target/" .. file_group
    else
        job_prefix = job_prefix .. "/rule/" .. file_group
    end

    -- call script files
    if not has_script then
        local script_files_name = opt.script_files_name
        local script_files = instance:script(script_files_name)
        if script_files then
            -- call custom script with jobgraph
            -- e.g.
            --
            -- target("test")
            --     on_build_files(function (target, jobgraph, sourcebatch, opt)
            --     end, {jobgraph = true})
            local distcc = instance:extraconf(script_files_name, "distcc")
            if instance:extraconf(script_files_name, "jobgraph") then
                script_files(target, jobgraph, sourcebatch, {distcc = distcc})
            elseif instance:extraconf(script_files_name, "batch") then
                wprint("%s.%s: the batch mode is deprecated, please use jobgraph mode instead of it, or disable `build.jobgraph` policy to use it.",
                    instance:fullname(), script_files_name)
            else
                -- call custom script directly
                -- e.g.
                --
                -- target("test")
                --     on_build_files(function (target, sourcebatch, opt)
                --     end)
                local jobname = string.format("%s/%s", job_prefix, script_files_name)
                jobgraph:add(jobname, function (index, total, opt)
                    script_files(target, sourcebatch, {progress = opt.progress, distcc = distcc})
                end)
            end
            has_script = true
        end
    end

    -- call script file
    if not has_script then
        local script_file_name = opt.script_file_name
        local script_file = instance:script(script_file_name)
        if script_file then
            -- call custom script with jobgraph
            -- e.g.
            --
            -- target("test")
            --     on_build_file(function (target, jobgraph, sourcefile, opt)
            --     end, {jobgraph = true})
            local distcc = instance:extraconf(script_file_name, "distcc")
            if instance:extraconf(script_file_name, "jobgraph") then
                local sourcekind = sourcebatch.sourcekind
                for _, sourcefile in ipairs(sourcebatch.sourcefiles) do
                    script_file(target, jobgraph, sourcefile, {sourcekind = sourcekind, distcc = distcc})
                end
            elseif instance:extraconf(script_file_name, "batch") then
                wprint("%s.%s: the batch mode is deprecated, please use jobgraph mode instead of it, or disable `build.jobgraph` policy to use it.",
                    instance:fullname(), script_file_name)
            else
                -- call custom script directly
                -- e.g.
                --
                -- target("test")
                --     on_build_file(function (target, sourcefile, opt)
                --     end)
                local jobname = string.format("%s/%s", job_prefix, script_file_name)
                jobgraph:add(jobname, function (index, total, opt)
                    local sourcekind = sourcebatch.sourcekind
                    for _, sourcefile in ipairs(sourcebatch.sourcefiles) do
                        script_file(target, sourcefile, {progress = opt.progress, sourcekind = sourcekind, distcc = distcc})
                    end
                end)
            end
            has_script = true
        end
    end

    -- call command script files
    -- e.g.
    --
    -- target("test")
    --     on_buildcmd_files(function (target, batchcmds, sourcebatch, opt)
    --     end)
    if not has_script then
        local scriptcmd_files_name = opt.scriptcmd_files_name
        local scriptcmd_files = instance:script(scriptcmd_files_name)
        if scriptcmd_files then
            local distcc = instance:extraconf(scriptcmd_files_name, "distcc")
            local jobname = string.format("%s/%s", job_prefix, scriptcmd_files_name)
            jobgraph:add(jobname, function (index, total, opt)
                local batchcmds_ = batchcmds.new({target = target})
                scriptcmd_files(target, batchcmds_, sourcebatch, {progress = opt.progress, distcc = distcc})
                batchcmds_:runcmds({changed = target:is_rebuilt(), dryrun = option.get("dry-run")})
            end)
            has_script = true
        end
    end

    -- call command script file
    -- e.g.
    --
    -- target("test")
    --     on_buildcmd_file(function (target, batchcmds, sourcefile, opt)
    --     end)
    if not has_script then
        local scriptcmd_file_name = opt.scriptcmd_file_name
        local scriptcmd_file = instance:script(scriptcmd_file_name)
        if scriptcmd_file then
            local distcc = instance:extraconf(scriptcmd_file_name, "distcc")
            local jobname = string.format("%s/%s", job_prefix, scriptcmd_file_name)
            jobgraph:add(jobname, function (index, total, opt)
                local batchcmds_ = batchcmds.new({target = target})
                local sourcekind = sourcebatch.sourcekind
                for _, sourcefile in ipairs(sourcebatch.sourcefiles) do
                    scriptcmd_file(target, batchcmds_, sourcefile, {progress = opt.progress, sourcekind = sourcekind, distcc = distcc})
                end
                batchcmds_:runcmds({changed = target:is_rebuilt(), dryrun = option.get("dry-run")})
            end)
            has_script = true
        end
    end
    return has_script
end

-- add file jobs with the given stage
-- stage: before, after or ""
--
function add_filejobs_with_stage(jobgraph, target, sourcebatches, stage, opt)
    opt = opt or {}
    local job_kind = opt.job_kind
    local job_kind_file = job_kind .. "_file"
    local job_kind_files = job_kind .. "_files"
    local job_kindcmd_file = job_kind .. "cmd_file"
    local job_kindcmd_files = job_kind .. "cmd_files"

    -- the group name, e.g. foo/after_prepare_files, bar/before_build_files
    local group_name = string.format("%s/%s_%s_files", target:fullname(), stage, job_kind)

    -- the script name, e.g. before/after_prepare_files, before/after_build_files
    local script_file_name = stage ~= "" and (job_kind_file .. "_" .. stage) or job_kind_file
    local script_files_name = stage ~= "" and (job_kind_files .. "_" .. stage) or job_kind_files

    -- the command script name, e.g. before/after_preparecmd_files, before/after_buildcmd_files
    local scriptcmd_file_name = stage ~= "" and (job_kindcmd_file .. "_" .. stage) or job_kindcmd_file
    local scriptcmd_files_name = stage ~= "" and (job_kindcmd_files .. "_" .. stage) or job_kindcmd_files

    -- build sourcebatches map
    local sourcebatches_map = {}
    local sourcebatches_for_target = {}
    for _, sourcebatch in pairs(sourcebatches) do
        local rulename = sourcebatch.rulename
        if rulename then
            local ruleinst = _get_rule(target, rulename)
            sourcebatches_map[ruleinst] = sourcebatch
            -- avoid duplicate scripts being called twice in the target,
            -- we just build sourcebatch with on_build_files scripts
            --
            -- for example, c++.build and c++.build.modules.builder rules have same sourcefiles,
            -- but we just build it for c++.build
            --
            -- @see https://github.com/xmake-io/xmake/issues/3171
            --
            if ruleinst:script("build_file") or ruleinst:script("build_files") then
                table.insert(sourcebatches_for_target, sourcebatch)
            end
        else
            table.insert(sourcebatches_for_target, sourcebatch)
        end
    end

    -- TODO sort rules and jobs
    local instances = {target}
    for _, r in ipairs(target:orderules()) do
        table.insert(instances, r)
    end

    -- call target and rules script
    local jobsize = jobgraph:size()
    jobgraph:group(group_name, function ()
        local script_opt = {
            script_file_name = script_file_name,
            script_files_name = script_files_name,
            scriptcmd_file_name = scriptcmd_file_name,
            scriptcmd_files_name = scriptcmd_files_name
        }
        local has_target_script = false
        for _, instance in ipairs(instances) do
            if instance == target then
                for _, sourcebatch in ipairs(sourcebatches_for_target) do
                    local has_script = add_filejobs_for_script(jobgraph, target, instance, sourcebatch, script_opt)
                    -- if custom target.on_build_file[s] exists, we need to ignore all scripts in rules
                    if has_script and stage == "" then
                        has_target_script = true
                    end
                end
            elseif not has_target_script then -- rule
                local sourcebatch = sourcebatches_map[instance]
                if sourcebatch then
                    add_filejobs_for_script(jobgraph, target, instance, sourcebatch, script_opt)
                end
            end
        end
    end)

    if jobgraph:size() > jobsize then
        return group_name
    end
end

-- add file jobs for the given target
function add_filejobs(jobgraph, target, opt)
    opt = opt or {}
    if not target:is_enabled() then
        return
    end

    -- get sourcebatches
    local sourcebatches
    local filepatterns = opt.filepatterns
    if filepatterns then
        sourcebatches = _match_sourcebatches(target, filepatterns)
    else
        sourcebatches = target:sourcebatches()
    end

    -- add file jobs with target stage, e.g. before_xxx_files -> on_xxx_files -> after_xxx_files
    local group        = add_filejobs_with_stage(jobgraph, target, sourcebatches, "", opt)
    local group_before = add_filejobs_with_stage(jobgraph, target, sourcebatches, "before", opt)
    local group_after  = add_filejobs_with_stage(jobgraph, target, sourcebatches, "after", opt)
    jobgraph:add_orders(group_before, group, group_after)
end

-- add file jobs for the given target and deps
function add_filejobs_and_deps(jobgraph, target, targetrefs, opt)
    local targetname = target:fullname()
    if not targetrefs[targetname] then
        targetrefs[targetname] = target
        add_filejobs(jobgraph, target, opt)
        for _, depname in ipairs(target:get("deps")) do
            local dep = project.target(depname, {namespace = target:namespace()})
            add_filejobs_and_deps(jobgraph, dep, targetrefs, opt)
        end
    end
end

-- get files jobs
function get_filejobs(targets_root, opt)
    local jobgraph = async_jobgraph.new(opt.job_kind)
    local targetrefs = {}
    for _, target in ipairs(targets_root) do
        add_filejobs_and_deps(jobgraph, target, targetrefs, opt)
    end
    return jobgraph
end

-- add link jobs for the given target
function add_linkjobs(jobgraph, target, opt)
    opt = opt or {}
    opt.job_kind = "link"
    local group        = add_targetjobs_with_stage(jobgraph, target, "", opt)
    local group_before = add_targetjobs_with_stage(jobgraph, target, "before", opt)
    local group_after  = add_targetjobs_with_stage(jobgraph, target, "after", opt)
    jobgraph:add_orders(group_before, group, group_after)
end

-- get link depfiles
function get_linkdepfiles(target)
    local extrafiles = {}
    for _, dep in ipairs(target:orderdeps()) do
        if dep:kind() == "static" then
            table.insert(extrafiles, dep:targetfile())
        end
    end
    local linkdepfiles = target:data("linkdepfiles")
    if linkdepfiles then
        table.join2(extrafiles, linkdepfiles)
    end
    local objectfiles = target:objectfiles()
    local depfiles = objectfiles
    if #extrafiles > 0 then
        depfiles = table.join(objectfiles, extrafiles)
    end
    return depfiles
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

-- run target-level jobs, e.g. on_prepare, on_build, ...
function run_targetjobs(targets_root, opt)
    opt = opt or {}
    local job_kind = opt.job_kind
    local jobgraph = get_targetjobs(targets_root, opt)
    if jobgraph and not jobgraph:empty() then
        local curdir = os.curdir()
        async_runjobs(job_kind, jobgraph, {on_exit = function (errors)
            import("utils.progress")
            if errors and progress.showing_without_scroll() then
                print("")
            end
        end, comax = option.get("jobs") or 1, curdir = curdir, distcc = opt.distcc})
        os.cd(curdir)
        return true
    end
end

-- run files-level jobs, e.g. on_prepare_files, on_build_files, ...
function run_filejobs(targets_root, opt)
    opt = opt or {}
    local job_kind = opt.job_kind
    local jobgraph = get_filejobs(targets_root, opt)
    if jobgraph and not jobgraph:empty() then
        local curdir = os.curdir()
        async_runjobs(job_kind, jobgraph, {on_exit = function (errors)
            import("utils.progress")
            if errors and progress.showing_without_scroll() then
                print("")
            end
        end, comax = option.get("jobs") or 1, curdir = curdir, distcc = opt.distcc})
        os.cd(curdir)
        return true
    end
end
