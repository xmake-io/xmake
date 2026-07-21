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
-- Copyright (C) 2015-present, Xmake Open Source Community.
--
-- @author      ruki
-- @file        object.lua
--

-- imports
import("core.base.option")
import("core.theme.theme")
import("core.tool.compiler")
import("core.project.depend")
import("private.cache.build_cache")
import("async.runjobs")
import("utils.progress")
import("private.service.distcc_build.client", {alias = "distcc_build_client"})
import("rules.c++.modules.support", {alias = "modules_support", rootdir = os.programdir(), try = true})
import("rules.c++.modules.mapper", {alias = "modules_mapper", rootdir = os.programdir(), try = true})

-- @see https://github.com/xmake-io/xmake/issues/7530
-- When build.c++.modules.reuse is enabled, a regular (non-.cppm) source file
-- that imports C++ modules gets "stolen back" into this plain c++.build
-- sourcebatch by rules/c++/modules/scanner.lua whenever it doesn't itself
-- provide a named module (e.g. a module implementation unit written as a
-- .cpp file). This generic jobgraph path has no notion of module import
-- dependencies, unlike rules/c++/modules/builder.lua's build_modules_for_jobgraph,
-- so under parallel jobgraph scheduling a reused module's producer job can
-- race with this job and fail with "module file '...' not found". This
-- mirrors builder.lua's _get_jobdeps ordering logic for that case only;
-- targets without C++ modules are completely unaffected.
local function _add_module_reuse_jobdeps(target, jobgraph, sourcefile, jobname)
    if not (modules_support and modules_mapper) then
        return
    end
    try
    {
        function()
            if not modules_support.contains_modules(target) then
                return
            end
            local module = modules_mapper.get(target, sourcefile)
            if not (module and module.deps) then
                return
            end
            local moduletype = modules_support.has_two_phase_compilation_support(target) and "bmi" or "onephase"
            for dep_name, dep in pairs(module.deps) do
                local dep_key = dep.headerunit and (dep_name .. dep.key) or dep_name
                local dep_module = modules_mapper.get(target, dep_key)
                if dep_module then
                    local dep_sourcefile = dep_module.sourcefile
                    if dep.headerunit then
                        dep_sourcefile = dep_sourcefile .. dep_module.key
                    end
                    local reused, from = modules_support.is_reused(target, dep_sourcefile)
                    if reused then
                        local dep_jobname = from:fullname() .. "/modules/build/" .. moduletype .. "/" .. dep_sourcefile
                        if jobgraph:has(dep_jobname) then
                            jobgraph:add_orders(dep_jobname, jobname)
                        else
                            local memcache = modules_support.memcache()
                            local dependent_jobs = memcache:get2("dependent_jobs", dep_jobname) or {}
                            table.insert(dependent_jobs, jobname)
                            memcache:set2("dependent_jobs", dep_jobname, dependent_jobs)
                        end
                    end
                end
            end
        end,
        catch
        {
            function(errors)
                if option.get("diagnosis") then
                    print("_add_module_reuse_jobdeps(%s, %s) failed: %s", target:fullname(), sourcefile, errors)
                end
            end
        }
    }
end

-- do build file
function _do_build_file(target, sourcefile, opt)

    -- get build info
    local objectfile = opt.objectfile
    local dependfile = opt.dependfile
    local sourcekind = opt.sourcekind

    -- load compiler
    local compinst = compiler.load(sourcekind, {target = target})

    -- get compile flags
    local compflags = compinst:compflags({target = target, sourcefile = sourcefile, configs = opt.configs})

    -- load dependent info
    local dependinfo = target:is_rebuilt() and {} or (depend.load(dependfile, {target = target}) or {})

    -- dry run?
    local dryrun = option.get("dry-run")

    -- need build this object?
    --
    -- we need use `os.mtime(dependfile)` to determine the mtime of the dependfile to avoid objectfile corruption due to compilation interruptions
    -- @see https://github.com/xmake-io/xmake/issues/748
    --
    -- we also need avoid the problem of not being able to recompile after the objectfile has been deleted
    -- @see https://github.com/xmake-io/xmake/issues/2551#issuecomment-1183922208
    --
    -- optimization:
    -- we enable time cache to speed up is_changed, because there are a lot of header files in depfiles.
    -- but we cannot cache it in link stage, maybe some objectfiles will be updated.
    -- @see https://github.com/xmake-io/xmake/issues/6089
    local depvalues = {compinst:program(), compflags}
    local lastmtime = os.isfile(objectfile) and os.mtime(dependfile) or 0
    if not dryrun and not depend.is_changed(dependinfo, {lastmtime = lastmtime, values = depvalues, timecache = true}) then
        return
    end

    -- is verbose?
    local verbose = option.get("verbose")

    -- exists ccache or distcc?
    -- we just show cache/distc to avoid confusion with third-party ccache/distcc
    local prefix = ""
    if build_cache.is_enabled(target) and build_cache.is_supported(sourcekind) then
        prefix = "cache "
    end
    if distcc_build_client.is_distccjob() and distcc_build_client.singleton():has_freejobs() then
        prefix = prefix .. "distc "
    end

    -- trace progress info
    if not opt.quiet then
        progress.show(opt.progress, "${color.build.object}%scompiling.$(mode) %s", prefix, sourcefile)
    end

    -- trace verbose info
    if verbose then
        -- show the full link command with raw arguments, it will expand @xxx.args for msvc/link on windows
        print(compinst:compcmd(sourcefile, objectfile, {compflags = compflags, rawargs = true}))
    end
    if not dryrun then

        -- do compile
        dependinfo.files = {}
        assert(compinst:compile(sourcefile, objectfile, {dependinfo = dependinfo, compflags = compflags}))

        -- update files and values to the depfiles
        dependinfo.values = depvalues
        table.insert(dependinfo.files, sourcefile)

        -- add precompiled header to the depfiles when building sourcefile
        local build_pch
        local pcxxoutputfile = target:pcoutputfile("cxx")
        local pcoutputfile = target:pcoutputfile("c")
        if pcxxoutputfile or pcoutputfile then
            -- https://github.com/xmake-io/xmake/issues/3988
            local extension = path.extension(sourcefile)
            if (extension:startswith(".h") or extension == ".inl") then
                build_pch = true
            end
        end
        if target:has_sourcekind("cxx") and pcxxoutputfile and not build_pch then
            table.insert(dependinfo.files, pcxxoutputfile)
        end
        if target:has_sourcekind("cc") and pcoutputfile and not build_pch then
            table.insert(dependinfo.files, pcoutputfile)
        end
        depend.save(dependinfo, dependfile)
    end
end

-- build object
function build_object(target, sourcefile, opt)
    local script = target:script("build_file", _do_build_file)
    if script then
        script(target, sourcefile, opt)
    end
end

-- build the source files
function build(target, sourcebatch, opt)
    for i = 1, #sourcebatch.sourcefiles do
        local sourcefile = sourcebatch.sourcefiles[i]
        opt.objectfile   = sourcebatch.objectfiles[i]
        opt.dependfile   = sourcebatch.dependfiles[i]
        opt.sourcekind   = assert(sourcebatch.sourcekind, "%s: sourcekind not found!", sourcefile)
        build_object(target, sourcefile, opt)
    end
end

-- add build jobs to batchjobs
function _add_batchjobs(target, batchjobs, sourcebatch, opt)
    local rootjob = opt.rootjob
    for i = 1, #sourcebatch.sourcefiles do
        local sourcefile = sourcebatch.sourcefiles[i]
        local objectfile = sourcebatch.objectfiles[i]
        local dependfile = sourcebatch.dependfiles[i]
        local sourcekind = assert(sourcebatch.sourcekind, "%s: sourcekind not found!", sourcefile)
        batchjobs:addjob(sourcefile, function (index, total, jobopt)
            progress.set_target(jobopt.progress, target)
            local build_opt = table.join({objectfile = objectfile, dependfile = dependfile, sourcekind = sourcekind, progress = jobopt.progress}, opt)
            build_object(target, sourcefile, build_opt)
        end, {rootjob = rootjob, distcc = opt.distcc})
    end
end

-- add build jobs to jobgraph
function _add_jobgraph(target, jobgraph, sourcebatch, opt)
    for i = 1, #sourcebatch.sourcefiles do
        local sourcefile = sourcebatch.sourcefiles[i]
        local objectfile = sourcebatch.objectfiles[i]
        local dependfile = sourcebatch.dependfiles[i]
        local sourcekind = assert(sourcebatch.sourcekind, "%s: sourcekind not found!", sourcefile)
        local jobname = target:fullname() .. "/obj/" .. sourcefile
        jobgraph:add(jobname, function (index, total, jobopt)
            progress.set_target(jobopt.progress, target)
            local build_opt = table.join({objectfile = objectfile, dependfile = dependfile, sourcekind = sourcekind, progress = jobopt.progress}, opt)
            build_object(target, sourcefile, build_opt)
        end, {distcc = opt.distcc})
        _add_module_reuse_jobdeps(target, jobgraph, sourcefile, jobname)
    end
end

-- build object files from source batch
--
-- @param target       the target instance
-- @param jobgraph    the job graph for dependency tracking
-- @param sourcebatch  the source batch {sourcefiles, sourcekind, ...}
-- @param opt          the options, e.g. {progress = {}}
--
function main(target, jobgraph, sourcebatch, opt)
    opt = opt or {}
    if jobgraph.add_orders then
        _add_jobgraph(target, jobgraph, sourcebatch, opt)
    else
        _add_batchjobs(target, jobgraph, sourcebatch, opt)
    end
end
