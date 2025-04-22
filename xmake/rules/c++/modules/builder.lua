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
-- @file        common.lua
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

-- build target modules
function _build_modules(target, sourcebatch, modules, opt)
    local objectfiles = sourcebatch.objectfiles
    for _, objectfile in ipairs(objectfiles) do
        local module = modules[objectfile]
        if not module then
            goto continue
        end

        local name, _, cppfile = support.get_provided_module(module)
        cppfile = cppfile or module.cppfile

        local deps = {}
        for name, req in pairs(module.requires or {}) do
            -- we need to use the full path as dep name if requre item is headerunit
            local dep = name
            if req.method:startswith("include-") and req.path then
                dep = req.path
            end
            dep = path.normalize(dep)
            local depname = target:fullname() .. "/module/" .. dep
            table.insert(deps, depname)
        end
        opt.build_module(deps, module, name, objectfile, cppfile)

        ::continue::
    end
end

-- build target headerunits
function _build_headerunits(target, headerunits, opt)
    local outputdir = support.headerunits_cachedir(target, {mkdir = true})
    if opt.stl_headerunit then
        outputdir = path.join(outputdir, "stl")
    end

    for _, headerunit in ipairs(headerunits) do
        local outputdir = outputdir
        if opt.stl_headerunit and headerunit.name:startswith("experimental/") then
            outputdir = path.join(outputdir, "experimental")
        end
        local bmifile = path.join(outputdir, path.filename(headerunit.name) .. support.get_bmi_extension(target))
        local key = path.normalize(headerunit.path)
        local build = should_build(target, headerunit.path, bmifile, {key = key, headerunit = true})
        if build then
            mark_build(target, key)
        end
        opt.build_headerunit(headerunit, key, bmifile, outputdir, build)
    end
end

-- check if flags are compatible for module reuse
function _are_flags_compatible(target, other, cppfile)
    local compinst1 = target:compiler("cxx")
    local flags1 = compinst1:compflags({sourcefile = cppfile, target = target})

    local compinst2 = other:compiler("cxx")
    local flags2 = compinst2:compflags({sourcefile = cppfile, target = other})

    -- strip unrelevent flags
    flags1 = support.strip_flags(target, flags1)
    flags2 = support.strip_flags(target, flags2)

    if #flags1 ~= #flags2 then
        return false
    end

    table.sort(flags1)
    table.sort(flags2)

    for i = 1, #flags1 do
        if flags1[i] ~= flags2[i] then
            return false
        end
    end
    return true
end

-- try to reuse modules from other target
function _try_reuse_modules(target, modules)
    for _, module in pairs(modules) do
        local name, provide, cppfile = support.get_provided_module(module)
        if not provide then
            goto continue
        end

        cppfile = cppfile or module.cppfile

        local fileconfig = target:fileconfig(cppfile)
        local public = fileconfig and (fileconfig.public or fileconfig.external)
        if not public then
            goto continue
        end

        for _, dep in ipairs(target:orderdeps()) do
            if not _are_flags_compatible(target, dep, cppfile) then
                goto nextdep
            end
            local mapped = get_from_target_mapper(dep, name)
            if mapped then
                support.memcache():set2(target:fullname() .. name, "reuse", true)
                add_module_to_target_mapper(target, mapped.name, mapped.sourcefile, mapped.bmi, table.join(mapped.opt or {}, {target = dep}))
                break
            end
            ::nextdep::
        end

        ::continue::
    end
    return modules
end

-- should we build this module or headerunit ?
function should_build(target, sourcefile, bmifile, opt)
    opt = opt or {}
    local objectfile = opt.objectfile
    local compinst = compiler.load("cxx", {target = target})
    local compflags = compinst:compflags({sourcefile = sourcefile, target = target})
    local dependfile = target:dependfile(bmifile or objectfile)
    local dependinfo = target:is_rebuilt() and {} or (depend.load(dependfile) or {})
    local depvalues = {compinst:program(), compflags}

    -- force rebuild a module if any of its module dependency is rebuilt
    local requires = opt.requires
    if requires then
        for required, _ in table.orderpairs(requires) do
            local m = get_from_target_mapper(target, required)
            if m then
                local rebuild = (m.opt and m.opt.target) and support.memcache():get2("should_build_in_" .. m.opt.target:fullname(), m.key)
                                                         or support.memcache():get2("should_build_in_" .. target:fullname(), m.key)
                if rebuild then
                    dependinfo.files = {}
                    table.insert(dependinfo.files, sourcefile)
                    dependinfo.values = depvalues
                    return true, dependinfo
                end
            end
        end
    end

    -- reused
    if opt.name then
        local m = get_from_target_mapper(target, opt.name)
        if m and m.opt and m.opt.target then
            local rebuild = support.memcache():get2("should_build_in_" .. m.opt.target:fullname(), m.key)
            if rebuild then
                dependinfo.files = {}
                table.insert(dependinfo.files, sourcefile)
                dependinfo.values = depvalues
            end
            return rebuild, dependinfo
        end
    end

    -- need build this object?
    local dryrun = option.get("dry-run")
    local lastmtime = os.isfile(bmifile or objectfile) and os.mtime(dependfile) or 0
    if dryrun or depend.is_changed(dependinfo, {lastmtime = lastmtime, values = depvalues}) then
        dependinfo.files = {}
        table.insert(dependinfo.files, sourcefile)
        dependinfo.values = depvalues
        return true, dependinfo
    end
    return false
end

-- generate meta module informations for package / other buildsystems import
--
-- e.g
-- {
--      "defines": ["FOO=BAR"]
--      "imports": ["std", "bar"]
--      "name": "foo"
--      "file": "foo.cppm"
-- }
function _generate_meta_module_info(target, name, sourcefile, requires)
    local modulehash = support.get_modulehash(target, sourcefile)
    local module_metadata = {name = name, file = path.join(modulehash, path.filename(sourcefile))}

    -- add definitions
    module_metadata.defines = _builder(target).get_module_required_defines(target, sourcefile)

    -- add imports
    if requires then
        for _name, _ in table.orderpairs(requires) do
            module_metadata.imports = module_metadata.imports or {}
            table.append(module_metadata.imports, _name)
        end
    end
    return module_metadata
end

function _target_module_map_cachekey(target)
    local mode = config.mode()
    return target:fullname() .. "module_mapper" .. (mode or "")
end

function _is_duplicated_headerunit(target, key)
    local _, mapper_keys = get_target_module_mapper(target)
    return mapper_keys[key]
end

function _builder(target)
    local cachekey = tostring(target)
    local builder = support.memcache():get2("builder", cachekey)
    if builder == nil then
        if target:has_tool("cxx", "clang", "clangxx", "clang_cl") then
            builder = import("clang.builder", {anonymous = true})
        elseif target:has_tool("cxx", "gcc", "gxx") then
            builder = import("gcc.builder", {anonymous = true})
        elseif target:has_tool("cxx", "cl") then
            builder = import("msvc.builder", {anonymous = true})
        else
            local _, toolname = target:tool("cxx")
            raise("compiler(%s): does not support c++ module!", toolname)
        end
        support.memcache():set2("builder", cachekey, builder)
    end
    return builder
end

function mark_build(target, name)
    support.memcache():set2("should_build_in_" .. target:fullname(), name, true)
end

-- build batchjobs for modules
function _build_batchjobs_for_modules(modules, batchjobs, rootjob)
    return buildjobs(modules, batchjobs, rootjob)
end

-- build modules for batchjobs
function _build_modules_for_batchjobs(target, batchjobs, sourcebatch, modules, opt)
    opt.rootjob = batchjobs:group_leave() or opt.rootjob
    batchjobs:group_enter(target:fullname() .. "/module/build_modules", {rootjob = opt.rootjob})

    -- add populate module job
    local modulesjobs = {}
    local populate_jobname = target:fullname() .. "/module/populate_module_map"
    modulesjobs[populate_jobname] = {
        name = populate_jobname,
        job = batchjobs:newjob(populate_jobname, function(_, _)
            _try_reuse_modules(target, modules)
            _builder(target).populate_module_map(target, modules)
        end)
    }

    -- add module jobs
    _build_modules(target, sourcebatch, modules, table.join(opt, {
        build_module = function(deps, module, name, objectfile, cppfile)
            local job_name = target:fullname() .. "/module/" .. path.normalize(name or cppfile)
            modulesjobs[job_name] = _builder(target).make_module_buildjobs(target, batchjobs, job_name, deps,
                {module = module, objectfile = objectfile, cppfile = cppfile})
        end
    }))

    -- build batchjobs for modules
    _build_batchjobs_for_modules(modulesjobs, batchjobs, opt.rootjob)
end

-- build modules for jobgraph
function _build_modules_for_jobgraph(target, jobgraph, sourcebatch, modules, opt)
    local jobdeps = {}
    local jobsize = jobgraph:size()
    local build_modules_group = target:fullname() .. "/module/build_modules"
    jobgraph:group(build_modules_group, function ()

        -- add populate module job
        local populate_jobname = target:fullname() .. "/module/populate_module_map"
        jobgraph:add(populate_jobname, function(index, total, opt)
            _try_reuse_modules(target, modules)
            _builder(target).populate_module_map(target, modules)
        end)

        -- add module jobs
        _build_modules(target, sourcebatch, modules, table.join(opt, {
            build_module = function(deps, module, name, objectfile, cppfile)
                local jobname = target:fullname() .. "/module/" .. path.normalize(name or cppfile)
                _builder(target).make_module_jobgraph(target, jobgraph, {
                    module = module, objectfile = objectfile, cppfile = cppfile
                })
                jobdeps[jobname] = table.join(populate_jobname, deps)
            end})
        )
    end)
    if jobgraph:size() > jobsize then
        return build_modules_group, jobdeps
    end
end

-- build modules for batchcmds
function _build_modules_for_batchcmds(target, batchcmds, sourcebatch, modules, opt)
    local depmtime = 0
    opt.progress = opt.progress or 0

    _try_reuse_modules(target, modules)
    _builder(target).populate_module_map(target, modules)

    -- build modules
    _build_modules(target, sourcebatch, modules, table.join(opt, {
        build_module = function(_, module, _, objectfile, cppfile)
            depmtime = math.max(depmtime, _builder(target).make_module_buildcmds(target, batchcmds, {
                module = module, cppfile = cppfile, objectfile = objectfile, progress = opt.progress}))
        end
    }))

    batchcmds:set_depmtime(depmtime)
end

-- build headerunits for batchjobs
function _build_headerunits_for_batchjobs(target, batchjobs, sourcebatch, modules, opt)

    local user_headerunits, stl_headerunits = scanner.get_headerunits(target, sourcebatch, modules)
    if not user_headerunits and not stl_headerunits then
       return
    end

    -- we need new group(headerunits)
    -- e.g. group(build_modules) -> group(headerunits)
    opt.rootjob = batchjobs:group_leave() or opt.rootjob
    batchjobs:group_enter(target:fullname() .. "/module/build_headerunits", {rootjob = opt.rootjob})

    local build_headerunits = function(headerunits)
        local modulesjobs = {}
        _build_headerunits(target, headerunits, table.join(opt, {
            build_headerunit = function(headerunit, key, bmifile, outputdir, build)
                local job_name = target:fullname() .. "/module/" .. path.normalize(key)
                local job = _builder(target).make_headerunit_buildjobs(target, job_name, batchjobs, headerunit, bmifile, outputdir, table.join(opt, {build = build}))
                if job then
                  modulesjobs[job_name] = job
                end
            end
        }))
        _build_batchjobs_for_modules(modulesjobs, batchjobs, opt.rootjob)
    end

    -- build stl header units first as other headerunits may need them
    if stl_headerunits then
        opt.stl_headerunit = true
        build_headerunits(stl_headerunits)
    end
    if user_headerunits then
        opt.stl_headerunit = false
        build_headerunits(user_headerunits)
    end
end

-- build headerunits for jobgraph
function _build_headerunits_for_jobgraph(target, jobgraph, sourcebatch, modules, opt)
    local user_headerunits, stl_headerunits = scanner.get_headerunits(target, sourcebatch, modules)
    if not user_headerunits and not stl_headerunits then
       return
    end

    -- we need new group(headerunits)
    -- e.g. group(build_modules) -> group(headerunits)
    local jobsize = jobgraph:size()
    local build_headerunits_group = target:fullname() .. "/module/build_headerunits"
    jobgraph:group(build_headerunits_group, function ()
        local build_headerunits = function(headerunits)
            local modulesjobs = {}
            _build_headerunits(target, headerunits, table.join(opt, {
                build_headerunit = function(headerunit, key, bmifile, outputdir, build)
                    local job_name = target:fullname() .. "/module/" .. path.normalize(key)
                    _builder(target).make_headerunit_jobgraph(target,
                        job_name, jobgraph, headerunit, bmifile, outputdir, table.join(opt, {build = build}))
                end
            }))
        end

        -- build stl header units first as other headerunits may need them
        if stl_headerunits then
            opt.stl_headerunit = true
            build_headerunits(stl_headerunits)
        end
        if user_headerunits then
            opt.stl_headerunit = false
            build_headerunits(user_headerunits)
        end
    end)
    if jobgraph:size() > jobsize then
        return build_headerunits_group
    end
end

-- build headerunits for batchcmds
function _build_headerunits_for_batchcmds(target, batchcmds, sourcebatch, modules, opt)
    local user_headerunits, stl_headerunits = scanner.get_headerunits(target, sourcebatch, modules)
    if not user_headerunits and not stl_headerunits then
       return
    end

    local build_headerunits = function(headerunits)
        local depmtime = 0
        _build_headerunits(target, headerunits, table.join(opt, {
            build_headerunit = function(headerunit, _, bmifile, outputdir, build)
                depmtime = math.max(depmtime, _builder(target).make_headerunit_buildcmds(target, batchcmds, headerunit, bmifile, outputdir, table.join({build = build}, opt)))
            end
        }))
        batchcmds:set_depmtime(depmtime)
    end

    -- build stl header units first as other headerunits may need them
    if stl_headerunits then
        opt.stl_headerunit = true
        build_headerunits(stl_headerunits)
    end
    if user_headerunits then
        opt.stl_headerunit = false
        build_headerunits(user_headerunits)
    end
end

-- build modules and headerunits, and we need to build headerunits first
function _build_modules_and_headerunits(target, jobgraph, sourcebatch, modules, opt)
    if jobgraph.add_orders then
        local build_modules_group, jobdeps = _build_modules_for_jobgraph(target, jobgraph, sourcebatch, modules, opt)
        local build_headerunits_group = _build_headerunits_for_jobgraph(target, jobgraph, sourcebatch, modules, opt)
        if build_modules_group then
            for jobname, deps in pairs(jobdeps) do
                for _, depname in ipairs(deps) do
                    jobgraph:add_orders(depname, jobname)
                end
            end
            if build_headerunits_group then
                jobgraph:add_orders(build_headerunits_group, build_modules_group)
            end
        end
    elseif jobgraph.runcmds then
        _build_headerunits_for_batchcmds(target, jobgraph, sourcebatch, modules, opt)
        _build_modules_for_batchcmds(target, jobgraph, sourcebatch, modules, opt)
    elseif jobgraph.newjob then -- deprecated
        _build_modules_for_batchjobs(target, jobgraph, sourcebatch, modules, opt)
        _build_headerunits_for_batchjobs(target, jobgraph, sourcebatch, modules, opt)
    end
end

-- generate metadata
function generate_metadata(target, modules)
    local public_modules
    for _, module in table.orderpairs(modules) do
        local _, _, cppfile = support.get_provided_module(module)
        local fileconfig = target:fileconfig(cppfile)
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
    runjobs(target:fullname() .. "/module/install_modules", function(index, total, jobopt)
        local module = public_modules[index]
        local name, _, cppfile = support.get_provided_module(module)
        local metafilepath = support.get_metafile(target, cppfile)
        progress.show(jobopt.progress, "${color.build.target}<%s> generating.module.metadata %s", target:fullname(), name)
        local metadata = _generate_meta_module_info(target, name, cppfile, module.requires)
        json.savefile(metafilepath, metadata)
    end, {comax = jobs, total = #public_modules})
end

-- flush target module mapper keys
function flush_target_module_mapper_keys(target)
    local memcache = support.memcache()
    memcache:set2(target:fullname(), "module_mapper_keys", nil)
end

-- get or create a target module mapper
function get_target_module_mapper(target)
    local memcache = support.memcache()
    local mapper = memcache:get2(target:fullname(), "module_mapper")
    if not mapper then
        mapper = {}
        memcache:set2(target:fullname(), "module_mapper", mapper)
    end

    -- we generate the keys map to optimise the efficiency of _is_duplicated_headerunit
    local mapper_keys = memcache:get2(target:fullname(), "module_mapper_keys")
    if not mapper_keys then
        mapper_keys = {}
        for _, item in pairs(mapper) do
            if item.key then
                mapper_keys[item.key] = item
            end
        end
        memcache:set2(target:fullname(), "module_mapper_keys", mapper_keys)
    end
    return mapper, mapper_keys
end

-- get a module or headerunit from target mapper
function get_from_target_mapper(target, name)
    local mapper = get_target_module_mapper(target)
    if mapper[name] then
        return mapper[name]
    end
end

-- add a module to target mapper
function add_module_to_target_mapper(target, name, sourcefile, bmifile, opt)
    local mapper = get_target_module_mapper(target)
    if not mapper[name] then
        mapper[name] = {name = name, key = name, bmi = bmifile, sourcefile = sourcefile, opt = opt}
    end
    flush_target_module_mapper_keys(target)
end

-- add a headerunit to target mapper
function add_headerunit_to_target_mapper(target, headerunit, bmifile)
    local mapper = get_target_module_mapper(target)
    local key = hash.uuid(path.normalize(headerunit.path))
    local deduplicated = _is_duplicated_headerunit(target, key)
    if deduplicated then
        mapper[headerunit.name] = {name = headerunit.name, key = key, aliasof = deduplicated.name, headerunit = headerunit}
    else
        mapper[headerunit.name] = {name = headerunit.name, key = key, headerunit = headerunit, bmi = bmifile}
    end
    flush_target_module_mapper_keys(target)
    return deduplicated and true or false
end

-- check if dependencies changed
function is_dependencies_changed(target, module)
    local cachekey = target:fullname() .. module.name
    local requires = hashset.from(table.keys(module.requires or {}))
    local oldrequires = support.memcache():get2(cachekey, "oldrequires")
    local changed = false
    if oldrequires then
        if oldrequires ~= requires then
           requires_changed = true
        else
           for required in requires:items() do
              if not oldrequires:has(required) then
                  requires_changed = true
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
        remove_files(support.modules_cachedir(target))
        if option.get("all") then
            remove_files(support.stlmodules_cachedir(target))
            support.localcache():clear()
            support.localcache():save()
        end
    end
end

function install(target)

    -- we cannot use target:data("cxx.has_modules"),
    -- because on_config will be not called when installing targets
    if support.contains_modules(target) then
        local modules = support.localcache():get2(target:fullname(), "c++.modules")
        generate_metadata(target, modules)

        support.add_installfiles_for_modules(target)
    end
end

function uninstall(target)
    if support.contains_modules(target) then
        support.add_installfiles_for_modules(target)
    end
end

function main(target, jobgraph, sourcebatch, opt)

    if target:data("cxx.has_modules") then
        -- get module dependencies
        local modules = scanner.get_module_dependencies(target, sourcebatch)
        if not target:is_moduleonly() then
            -- avoid building non referenced modules
            local build_objectfiles, link_objectfiles = scanner.sort_modules_by_dependencies(target, sourcebatch.objectfiles, modules)
            sourcebatch.objectfiles = build_objectfiles

            -- build modules and headerunits
            _build_modules_and_headerunits(target, jobgraph, sourcebatch, modules, opt)
            sourcebatch.objectfiles = link_objectfiles
        else
            sourcebatch.objectfiles = {}
        end

        support.localcache():set2(target:fullname(), "c++.modules", modules)
        support.localcache():save()
    else
        -- avoid duplicate linking of object files of non-module programs
        sourcebatch.objectfiles = {}
    end
end
