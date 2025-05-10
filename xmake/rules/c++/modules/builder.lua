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
-- @author      ruki, Arthapz
-- @file        builder.lua
--

-- imports
import("core.base.json")
import("core.base.option")
import("core.base.hashset")
import("async.runjobs")
import("private.action.clean.remove_files")
import("private.async.buildjobs")
import("core.tool.compiler")
import("core.project.config")
import("core.project.depend")
import("utils.progress")
import("support")
import("scanner")
import("mapper")

function _builder(target)
    return support.import_implementation_of(target, "builder")
end

-- generate meta module informations for package / other buildsystems import
--
-- e.g
-- {
--      "flags": ["--std=c++23"]
--      "imports": ["std", "bar"]
--      "name": "foo"
--      "file": "foo.cppm"
-- }
function _generate_meta_module_info(target, module)
    local fileconfig = target:fileconfig(module.sourcefile)
    local defines = table.join(target:get("defines") or {}, fileconfig and fileconfig.defines or {})
    local undefines = table.join(target:get("undefines") or {}, fileconfig and fileconfig.undefines or {})
    local modulehash = support.get_modulehash(module.sourcefile)
    local module_metadata = {name = module.name, file = path.join(modulehash, path.filename(module.sourcefile)), defines = defines, undefines = undefines}

    -- add imports
    for name, _ in table.orderpairs(module.deps) do
        module_metadata.imports = module_metadata.imports or {}
        table.insert(module_metadata.imports, name)
    end
    return module_metadata
end

function _get_module_buildgroup_for(target, moduletype)
    return target:fullname() .. "/modules/build/" .. moduletype
end

function _get_module_buildfilejob_for(target, sourcefile, moduletype)
    return _get_module_buildgroup_for(target, moduletype) .. "/" .. sourcefile
end

function _get_headerunit_buildgroup_for(target)
    return target:fullname() .. "/headerunit/build"
end

function _get_headerunit_buildfilejob_for(target, sourcefile)
    return _get_headerunit_buildgroup_for(target) .. "/" .. sourcefile
end

function _get_buildfilejob_for(target, sourcefile, opt)
    if opt and opt.headerunit then
        return _get_headerunit_buildfilejob_for(target, sourcefile)
    end
    return _get_module_buildfilejob_for(target, sourcefile, opt.moduletype)
end

function _get_jobdeps(target, module, jobgraph, buildfilejob)

    local memcache = support.memcache()
    local jobdeps = {}
    local moduletype = support.has_two_phase_compilation_support(target) and "bmi" or "onephase"
    for dep_name, dep in pairs(module.deps) do
        if dep.headerunit then
            dep_name = dep_name .. dep.key
        end
        local dep_module = mapper.get(target, dep_name)
        local dep_sourcefile = dep_module.sourcefile
        if dep.headerunit then
            dep_sourcefile = dep_sourcefile .. dep_module.key
        end

        local reused, from = support.is_reused(target, dep_sourcefile)
        local dep_jobname
        if dep_module.headerunit then
            dep_jobname = _get_headerunit_buildfilejob_for(reused and from or target, dep_sourcefile)
        else
            dep_jobname = _get_module_buildfilejob_for(reused and from or target, dep_sourcefile, moduletype)
        end
        -- if dep_jobname is available, order it now
        if jobgraph:has(dep_jobname) then
            jobdeps[buildfilejob] = jobdeps[buildfilejob] or {}
            table.insert(jobdeps[buildfilejob], dep_jobname)
        -- if dep_jobname is not currently available, save deps for later ordering
        else
            local dependent_jobs = memcache:get2("dependent_jobs", dep_jobname) or {}
            table.insert(dependent_jobs, buildfilejob)
            memcache:set2("dependent_jobs", dep_jobname, dependent_jobs)
        end
    end
    return jobdeps
end

function _get_saved_jobdeps_for(buildfilejob)
    local memcache = support.memcache()
    local dependent_jobs = memcache:get2("dependent_jobs", buildfilejob)
    local jobdeps = {}
    for _, dependent_job in ipairs(dependent_jobs) do
        jobdeps[dependent_job] = jobdeps[dependent_job] or {}
        table.insert(jobdeps[dependent_job], buildfilejob)
    end
    return jobdeps
end

-- should we build this module or headerunit ?
function should_build(target, module)

    local memcache = support.memcache()
    local _should_build = memcache:get2(target:fullname(), "should_build_" .. module.sourcefile)
    if _should_build == nil then
        local key = module.headerunit and module.sourcefile .. module.key or module.sourcefile
        local reused, from = support.is_reused(target, key)
        if reused then
            local build = should_build(from, module)
            memcache:set2(target:fullname(), "should_build_" .. module.sourcefile, build)
            return build
        end
        local compinst = compiler.load("cxx", {target = target})
        local compflags = compinst:compflags({sourcefile = module.sourcefile, target = target})

        local dependfile = target:dependfile(module.bmifile or module.objectfile)
        local dependinfo = {}
        dependinfo.files = {module.sourcefile}
        dependinfo.values = {compinst:program(), compflags}
        local objectfile_exists = (module.headerunit or support.is_bmionly(target, module.sourcefile)) and true or os.isfile(module.objectfile)
        dependinfo.lastmtime = (os.isfile(module.bmifile or module.objectfile) and objectfile_exists) and os.mtime(dependfile) or 0

        local old_dependinfo = target:is_rebuilt() and {} or (depend.load(dependfile) or {})
        old_dependinfo.files = {module.sourcefile}

        -- force rebuild a module if any of its module dependency is rebuilt
        for dep_name, dep_module in table.orderpairs(module.deps) do
            local mapped_dep = mapper.get(target, dep_module.headerunit and dep_name .. dep_module.key or dep_name)

            if should_build(target, mapped_dep) then
                depend.save(dependinfo, dependfile)
                memcache:set2(target:fullname(), "should_build_" .. module.sourcefile, true)
                return true
            end
        end

        -- need build this object?
        local dryrun = option.get("dry-run")
        if dryrun or depend.is_changed(old_dependinfo, dependinfo) then
            depend.save(dependinfo, dependfile)
            memcache:set2(target:fullname(), "should_build_" .. module.sourcefile, true)
            return true
        end
        memcache:set2(target:fullname(), "should_build_" .. module.sourcefile, false)
        return false
    end
    return _should_build
end

-- build modules for jobgraph
-- only build bmis if two phase compilation is supported
-- it not build also objectfiles
function build_modules_for_jobgraph(target, jobgraph, built_modules)

    local builder = _builder(target)
    local has_two_phase_compilation_support = support.has_two_phase_compilation_support(target)
    local jobdeps = {}
    local buildfilejobs = {}

    -- if two phase supported only build interface and implementation named modules bmi
    local _built_modules = {}
    for _, sourcefile in ipairs(built_modules) do
        local module = mapper.get(target, sourcefile)
        if module.interface or module.implementation then
            table.insert(_built_modules, sourcefile)
        else
            if not support.is_bmionly(target, sourcefile) then
                local buildfilejob = _get_module_buildfilejob_for(target, sourcefile, "objectfile")
                table.join2(jobdeps, _get_jobdeps(target, module, jobgraph, buildfilejob))
                table.insert(buildfilejobs, buildfilejob)
                local objbuildfilejob = target:fullname() .. "/obj/" .. sourcefile
                if jobgraph:has(objbuildfilejob) then
                    jobdeps[objbuildfilejob] = {buildfilejob}
                end
            end
        end
    end

    -- add module jobs
    local moduletype = has_two_phase_compilation_support and "bmi" or "onephase"
    local buildgroup = _get_module_buildgroup_for(target, moduletype)
    jobgraph:group(buildgroup, function()
        for _, sourcefile in ipairs(_built_modules) do
            local module = mapper.get(target, sourcefile)
            local bmionly = support.is_bmionly(target, module.sourcefile)
            local buildfilejob = _get_module_buildfilejob_for(target, sourcefile, moduletype)
            table.insert(buildfilejobs, buildfilejob)
            jobgraph:add(buildfilejob, function(_, _, jobopt)
                -- build bmi if named job
                jobopt.bmi = module.interface or module.implementation
                -- build objectfile here if two phase compilation is not supported
                jobopt.objectfile = not has_two_phase_compilation_support and not bmionly
                builder.make_module_job(target, module, jobopt)
            end)
            table.join2(jobdeps, _get_jobdeps(target, module, jobgraph, buildfilejob))

            -- if two phase compilation supported set jobdeps for objectfile job
            if has_two_phase_compilation_support and not bmionly then
                local objbuildfilejob = _get_module_buildfilejob_for(target, sourcefile, "objectfile")
                jobdeps[objbuildfilejob] = {buildfilejob}
            end
        end
    end)

    -- insert saved jobdeps
    for _, buildfilejob in ipairs(buildfilejobs) do
        table.join2(jobdeps, _get_saved_jobdeps_for(buildfilejob))
    end

    -- apply jobdeps
    for jobname, deps in pairs(jobdeps) do
        for _, depname in ipairs(deps) do
            jobgraph:add_orders(depname, jobname)
        end
    end
end

-- build modules objectfiles for jobgraph if two phase compilation is supported
function build_objectfiles_for_jobgraph(target, jobgraph, built_modules)

    local builder = _builder(target)
    local has_two_phase_compilation_support = support.has_two_phase_compilation_support(target)
    local buildgroup = _get_module_buildgroup_for(target, "objectfile")
    local _built_modules = {}
    if has_two_phase_compilation_support then
        _built_modules = built_modules
    else
        for _, sourcefile in ipairs(built_modules) do
            local module = mapper.get(target, sourcefile)
            if not module.interface and not module.implementation then
                table.insert(_built_modules, sourcefile)
            end
        end
    end
    jobgraph:group(buildgroup, function()
        for _, sourcefile in ipairs(_built_modules) do
            if not support.is_bmionly(target, sourcefile) then
                local module = mapper.get(target, sourcefile)
                local buildfilejob = _get_module_buildfilejob_for(target, sourcefile, "objectfile")
                jobgraph:add(buildfilejob, function(_, _, jobopt)
                    jobopt.bmi = false
                    jobopt.objectfile = true
                    builder.make_module_job(target, module, jobopt)
                end)
            end
        end
    end)
end

-- build batchjobs for modules
function build_batchjobs_for_modules(modules, batchjobs, rootjob)
    return buildjobs(modules, batchjobs, rootjob)
end

-- build modules for batchjobs (deprecated)
function build_modules_for_batchjobs(target, batchjobs, built_modules, opt)

    opt.rootjob = batchjobs:group_leave() or opt.rootjob
    batchjobs:group_enter(target:fullname() .. "/build_cxxmodules_bmi", {rootjob = opt.rootjob})

    local builder = _builder(target)
    local has_two_phase_compilation_support = support.has_two_phase_compilation_support(target)

    -- if two phase supported only build interface and implementation named modules bmi
    local _built_modules = {}
    for _, sourcefile in ipairs(built_modules) do
        local module = mapper.get(target, sourcefile)
        if module.interface or module.implementation then
            table.insert(_built_modules, sourcefile)
        end
    end

    -- add module jobs
    local jobs
    local moduletype = has_two_phase_compilation_support and "bmi" or "onephase"
    for _, sourcefile in ipairs(_built_modules) do
        jobs = jobs or {}
        local bmionly = support.is_bmionly(target, sourcefile)
        local module = mapper.get(target, sourcefile)

        local buildfilejob = _get_module_buildfilejob_for(target, sourcefile, moduletype)
        local deps = {}
        for dep_name, dep in pairs(module.deps) do
            if dep.headerunit then
                dep_name = dep_name .. dep.key
            end
            local dep_module = mapper.get(target, dep_name)
            local dep_sourcefile = dep_module.sourcefile
            if dep.headerunit then
                dep_sourcefile = dep_sourcefile .. dep_module.key
            end

            local reused, from = support.is_reused(target, dep_sourcefile)
            local dep_jobname
            if dep_module.headerunit then
                dep_jobname = _get_headerunit_buildfilejob_for(reused and from or target, dep_sourcefile)
            else
                dep_jobname = _get_module_buildfilejob_for(reused and from or target, dep_sourcefile, moduletype)
            end
            table.insert(deps, dep_jobname)
        end
        jobs[buildfilejob] = {
            name = buildfilejob,
            deps = deps,
            sourcefile = module.sourcefile,
            job = batchjobs:newjob(buildfilejob, function(_, _, jobopt)
                -- build bmi if named job
                jobopt.bmi = module.interface or module.implementation
                -- build objectfile here if two phase compilation is not supported
                jobopt.objectfile = not has_two_phase_compilation_support and not bmionly
                builder.make_module_job(target, module, jobopt)
            end)}
    end

    return jobs
end

-- build modules objectfiles for batchjobs if two phase compilation is supported (deprecated)
function build_objectfiles_for_batchjobs(target, batchjobs, built_modules, opt)

    opt.rootjob = batchjobs:group_leave() or opt.rootjob
    batchjobs:group_enter(target:fullname() .. "/build_cxxmodules_objectfiles", {rootjob = opt.rootjob})
    local builder = _builder(target)
    local has_two_phase_compilation_support = support.has_two_phase_compilation_support(target)
    local _built_modules = {}
    if has_two_phase_compilation_support then
        _built_modules = built_modules
    else
        for _, sourcefile in ipairs(built_modules) do
            local module = mapper.get(target, sourcefile)
            if not module.interface and not module.implementation then
                table.insert(_built_modules, sourcefile)
            end
        end
    end

    local jobs
    for _, sourcefile in ipairs(_built_modules) do
        if not support.is_bmionly(target, sourcefile) then
            jobs = jobs or {}
            local module = mapper.get(target, sourcefile)
            local buildfilejob = _get_module_buildfilejob_for(target, sourcefile, "objectfile")
            jobs[buildfilejob] = {
                name = buildfilejob,
                sourcefile = module.sourcefile,
                job = batchjobs:newjob(buildfilejob, function(_, _, jobopt)
                    jobopt.bmi = false
                    jobopt.objectfile = true
                    builder.make_module_job(target, module, jobopt)
                end)}
        end
    end

    return jobs
end

-- build modules for batchcmds
function build_modules_for_batchcmds(target, batchcmds, built_modules, opt)
    opt.progress = opt.progress or 0
    local depmtime = 0
    -- build modules
    local builder = _builder(target)
    local has_two_phase_compilation_support = support.has_two_phase_compilation_support(target)

    local _built_modules = {}
    for _, sourcefile in ipairs(built_modules) do
        local module = mapper.get(target, sourcefile)
        if module.interface or module.implementation then
            table.insert(_built_modules, sourcefile)
        end
    end

    for _, sourcefile in ipairs(_built_modules) do
        local bmionly = support.is_bmionly(target, sourcefile)
        local module = mapper.get(target, sourcefile)
        local jobopt = {}
        jobopt.bmi = module.interface or module.implementation
        jobopt.objectfile = not has_two_phase_compilation_support and not bmionly
        jobopt.progress = opt.progress
        depmtime = math.max(depmtime, builder.make_module_buildcmds(target, batchcmds, module, jobopt))
    end
    batchcmds:set_depmtime(depmtime)
end

-- build modules objectfiles for batchcmds if two phase compilation is supported
function build_objectfiles_for_batchcmds(target, batchcmds, built_modules, opt)

    opt.progress = opt.progress or 0
    local depmtime = 0
    local builder = _builder(target)
    local has_two_phase_compilation_support = support.has_two_phase_compilation_support(target)
    local _built_modules = {}
    if has_two_phase_compilation_support then
        _built_modules = built_modules
    else
        for _, sourcefile in ipairs(built_modules) do
            local module = mapper.get(target, sourcefile)
            if not module.interface and not module.implementation then
            table.insert(_built_modules, sourcefile)
            end
        end
    end

    for _, sourcefile in ipairs(_built_modules) do
        if not support.is_bmionly(target, sourcefile) then
            local module = mapper.get(target, sourcefile)
            local jobopt = {}
            jobopt.bmi = false
            jobopt.objectfile = true
            jobopt.progress = opt.progress
            depmtime = math.max(depmtime, builder.make_module_buildcmds(target, batchcmds, module, jobopt))
        end
    end
    batchcmds:set_depmtime(depmtime)
end

-- build headerunits for jobgraph
function build_headerunits_for_jobgraph(target, jobgraph, built_stlheaderunits, built_headerunits)

    local builder = _builder(target)
    function make_headerunit_job(headerfile, opt)
        local reused, from = support.is_reused(target, headerfile)
        local _target = reused and from or target
        local headerunit = mapper.get(target, headerfile)
        if not headerunit.alias then
            local buildfilejob = _get_headerunit_buildfilejob_for(_target, headerunit.sourcefile .. headerunit.key)
            if not jobgraph:has(buildfilejob) then
                jobgraph:add(buildfilejob, function(_, _, jobopt)
                    builder.make_headerunit_job(_target, headerunit, table.join(jobopt, opt))
                end)
            end
        end
    end

    local headerunit_buildgroup = _get_headerunit_buildgroup_for(target)
    if built_stlheaderunits then
        -- build stl header units first as other headerunits may need them
        jobgraph:group(headerunit_buildgroup, function()
            for _, headerfile in ipairs(built_stlheaderunits) do
                make_headerunit_job(headerfile, {stl_headerunit = true})
            end
        end)
    end

    if built_headerunits then
        jobgraph:group(headerunit_buildgroup, function()
            for _, headerfile in ipairs(built_headerunits) do
                make_headerunit_job(headerfile)
            end
        end)
    end
end

-- build headerunits for batchjobs
function build_headerunits_for_batchjobs(target, batchjobs, built_stlheaderunits, built_headerunits, opt)

    -- we need new group(headerunits)
    -- e.g. group(build_modules) -> group(headerunits)
    opt.rootjob = batchjobs:group_leave() or opt.rootjob
    batchjobs:group_enter(target:fullname() .. "/build_headerunits", {rootjob = opt.rootjob})
    local builder = _builder(target)
    local jobs = {}
    function make_headerunit_job(headerfile, opt)
        local reused, from = support.is_reused(target, headerfile)
        local _target = reused and from or target
        local headerunit = mapper.get(target, headerfile)
        if not headerunit.alias then
            local buildfilejob = _get_headerunit_buildfilejob_for(_target, headerunit.sourcefile .. headerunit.key)
            jobs[buildfilejob] = {
                name = buildfilejob,
                sourcefile = headerunit.sourcefile,
                job = batchjobs:newjob(buildfilejob, function(_, _, jobopt)
                    builder.make_headerunit_job(_target, headerunit, table.join(jobopt, opt))
                end)}
        end
    end

    if built_stlheaderunits then
        -- build stl header units first as other headerunits may need them
        for _, headerfile in ipairs(built_stlheaderunits) do
            make_headerunit_job(headerfile, {stl_headerunit = true})
        end
    end

    if built_headerunits then
        for _, headerfile in ipairs(built_headerunits) do
            make_headerunit_job(headerfile)
        end
    end
    return jobs
end

-- build headerunits for batchcmds
function build_headerunits_for_batchcmds(target, batchcmds, built_stlheaderunits, built_headerunits, opt)

    local builder = _builder(target)
    function make_headerunit_buildcmds(headerfile, jobopt)
        local reused, from = support.is_reused(target, headerfile)
        local _target = reused and from or target
        local headerunit = mapper.get(target, headerfile)
        if not headerunit.alias then
            builder.make_headerunit_buildcmds(_target, batchcmds, headerunit, table.join(opt, jobopt))
        end
    end

    -- build stl header units first as other headerunits may need them
    -- opt.stl_headerunit = true
    for _, headerfile in ipairs(built_stlheaderunits) do
        make_headerunit_buildcmds(headerfile, {stl_headerunit = true})
    end
    -- opt.stl_headerunit = false
    for _, headerfile in ipairs(built_headerunits) do
        make_headerunit_buildcmds(headerfile)
    end
end

function generate_metadata(target, modules)
    local public_modules
    for sourcefile, module in table.orderpairs(modules) do
        local fileconfig = target:fileconfig(sourcefile)
        local public = fileconfig and fileconfig.public
        if public then
            public_modules = public_modules or {}
            table.insert(public_modules, module)
        end
    end

    if not public_modules then
        return
    end

    local jobs = option.get("jobs") or os.default_njob()
    runjobs(target:fullname() .. "_install_modules", function(index, _, jobopt)
        local module = public_modules[index]
        local metafilepath = support.get_metafile(target, module)
        progress.show(jobopt.progress, "${color.build.target}<%s> generating.module.metadata %s", target:fullname(), module.name)
        local metadata = _generate_meta_module_info(target, module)
        json.savefile(metafilepath, metadata)
    end, {comax = jobs, total = #public_modules})
end

-- check if dependencies changed
function is_dependencies_changed(target, module)
    local cachekey = target:fullname() .. (module.name or module.sourcefile)
    local requires = hashset.from(table.keys(module.deps or {}))
    local oldrequires = support.memcache():get2(cachekey, "oldrequires")
    local changed = false
    if oldrequires then
        if oldrequires ~= requires then
           changed = true
        else
           for required in requires:items() do
              if not oldrequires:has(required) then
                  changed = true
                  break
              end
           end
        end
    end
    return requires, changed
end

function clean(target)
    -- we cannot use target:data("cxx.has_modules"),
    -- because on_config will be not called when cleaning targets
    if support.contains_modules(target) then
        remove_files(support.modules_cachedir(target, {interface = true}))
        remove_files(support.modules_cachedir(target, {interface = false}))
        remove_files(support.modules_cachedir(target, {headerunit = true}))
        if option.get("all") then
            support.localcache():clear()
            support.localcache():save()
        end
    end
end

function build_bmis(target, jobgraph, _, opt)
    opt = opt or {}
    if target:data("cxx.has_modules") then
        if target:is_moduleonly() and not target:data("cxx.modules.reused") then
            return
        end
        local modules = scanner.get_modules(target)
        -- avoid building non referenced modules
        local built_modules, built_headerunits, _ = scanner.sort_modules_by_dependencies(target, modules, {jobgraph = target:policy("build.jobgraph")})
        local headerunits, stlheaderunits = scanner.sort_headerunits(target, built_headerunits)
        if jobgraph.add_orders then -- jobgraph
            -- build headerunits
            if stlheaderunits or headerunits then
                build_headerunits_for_jobgraph(target, jobgraph, stlheaderunits, headerunits)
            end

            -- build modules
            build_modules_for_jobgraph(target, jobgraph, built_modules)
        elseif jobgraph.newjob then -- batchjobs (deprecated)
            opt.batchjobs = true
            -- build headerunits
            local headerunit_jobs = build_headerunits_for_batchjobs(target, jobgraph, stlheaderunits, headerunits, opt)

            -- build modules
            local module_jobs = build_modules_for_batchjobs(target, jobgraph, built_modules, opt)

            build_batchjobs_for_modules(table.join(headerunit_jobs or {}, module_jobs or {}), jobgraph, opt.rootjob)
        elseif jobgraph.runcmds then -- batchcmds
            opt.progress = opt.progress or 0
            -- build headerunits
            build_headerunits_for_batchcmds(target, jobgraph, stlheaderunits, headerunits, opt)

            local append_requires_flags = _builder(target).append_requires_flags
            if append_requires_flags then
                append_requires_flags(target, built_modules)
            end

            -- build modules
            build_modules_for_batchcmds(target, jobgraph, built_modules, opt)
        else
            assert(false, "shouldn't be here :D")
        end
    end
end

function build_objectfiles(target, jobgraph, _, opt)

    if target:data("cxx.has_modules") then
        if target:is_moduleonly() and not target:data("cxx.modules.reused") then
            return
        end
        local modules = scanner.get_modules(target)
        -- avoid building non referenced modules
        local built_modules, _, _ = scanner.sort_modules_by_dependencies(target, modules, {jobgraph = target:policy("build.jobgraph")})
        local append_requires_flags = _builder(target).append_requires_flags
        if append_requires_flags then
            append_requires_flags(target, built_modules)
        end

        if jobgraph.add_orders then -- jobgraph
            -- build modules objectfiles
            build_objectfiles_for_jobgraph(target, jobgraph, built_modules)
        elseif jobgraph.newjob then -- batchjobs (deprecated)
            opt.batchjobs = true
            -- build modules objectfiles
            local jobs = table.join(build_objectfiles_for_batchjobs(target, jobgraph, built_modules, opt) or {}, jobs or {})

            build_batchjobs_for_modules(jobs, jobgraph, opt.rootjob)
        elseif jobgraph.runcmds then -- batchcmds
            -- build modules objectfiles
            build_objectfiles_for_batchcmds(target, jobgraph, built_modules, opt)
        else
            assert(false, "shouldn't be here :D")
        end
    end
end

