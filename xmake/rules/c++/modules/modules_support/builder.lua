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
import("private.async.buildjobs")
import("core.tool.compiler")
import("core.project.config")
import("core.project.depend")
import("utils.progress")
import("compiler_support")
import("dependency_scanner")

-- build target modules
function _build_modules(target, sourcebatch, modules, opt)
    local objectfiles = sourcebatch.objectfiles
    for _, objectfile in ipairs(objectfiles) do
        local module = modules[objectfile]
        if not module then
            goto continue
        end

        local name, _, cppfile = compiler_support.get_provided_module(module)
        cppfile = cppfile or module.cppfile

        local deps = {}
        for _, dep in ipairs(table.keys(module.requires or {})) do
            table.insert(deps, opt.batchjobs and target:name() .. dep or dep)
        end

        opt.build_module(deps, module, name, objectfile, cppfile)

        ::continue::
    end
end

-- build target headerunits
function _build_headerunits(target, headerunits, opt)

    local outputdir = compiler_support.headerunits_cachedir(target, {mkdir = true})
    if opt.stl_headerunit then
        outputdir = path.join(outputdir, "stl")
    end

    for _, headerunit in ipairs(headerunits) do
        local outputdir = outputdir
        if opt.stl_headerunit and headerunit.name:startswith("experimental/") then
            outputdir = path.join(outputdir, "experimental")
        end
        local bmifile = path.join(outputdir, path.filename(headerunit.name) .. compiler_support.get_bmi_extension(target))
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
    flags1 = compiler_support.strip_flags(target, flags1)
    flags2 = compiler_support.strip_flags(target, flags2)

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
        local name, provide, cppfile = compiler_support.get_provided_module(module)
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
                compiler_support.memcache():set2(target:name() .. name, "reuse", true)
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
                local rebuild = (m.opt and m.opt.target) and compiler_support.memcache():get2("should_build_in_" .. m.opt.target:name(), m.key)
                                                         or compiler_support.memcache():get2("should_build_in_" .. target:name(), m.key)
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
            local rebuild = compiler_support.memcache():get2("should_build_in_" .. m.opt.target:name(), m.key)
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

    local modulehash = compiler_support.get_modulehash(target, sourcefile)
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
    return target:name() .. "module_mapper" .. (mode or "")
end

function _is_duplicated_headerunit(target, key)
    local _, mapper_keys = get_target_module_mapper(target)
    return mapper_keys[key]
end

function _builder(target)
    local cachekey = tostring(target)
    local builder = compiler_support.memcache():get2("builder", cachekey)
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
        compiler_support.memcache():set2("builder", cachekey, builder)
    end
    return builder
end

function mark_build(target, name)
    compiler_support.memcache():set2("should_build_in_" .. target:name(), name, true)
end

-- build batchjobs for modules
function build_batchjobs_for_modules(modules, batchjobs, rootjob)
    return buildjobs(modules, batchjobs, rootjob)
end

-- build modules for batchjobs
function build_modules_for_batchjobs(target, batchjobs, sourcebatch, modules, opt)
    opt.rootjob = batchjobs:group_leave() or opt.rootjob
    batchjobs:group_enter(target:name() .. "/build_modules", {rootjob = opt.rootjob})

    -- add populate module job
    local modulesjobs = {}
    local populate_jobname = target:name() .. "_populate_module_map"
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
        local job_name = name and target:name() .. name or cppfile
        modulesjobs[job_name] = _builder(target).make_module_buildjobs(target, batchjobs, job_name, deps,
            {module = module, objectfile = objectfile, cppfile = cppfile})
      end
    }))

    -- build batchjobs for modules
    build_batchjobs_for_modules(modulesjobs, batchjobs, opt.rootjob)
end

-- build modules for batchcmds
function build_modules_for_batchcmds(target, batchcmds, sourcebatch, modules, opt)

    local depmtime = 0
    opt.progress = opt.progress or 0

    _try_reuse_modules(target, modules)
    _builder(target).populate_module_map(target, modules)

    -- build modules
    _build_modules(target, sourcebatch, modules, table.join(opt, {
       build_module = function(_, module, _, objectfile, cppfile)
          depmtime = math.max(depmtime, _builder(target).make_module_buildcmds(target, batchcmds, {module = module, cppfile = cppfile, objectfile = objectfile, progress = opt.progress}))
      end
    }))

    batchcmds:set_depmtime(depmtime)
end

-- generate headerunits for batchjobs
function build_headerunits_for_batchjobs(target, batchjobs, sourcebatch, modules, opt)

    local user_headerunits, stl_headerunits = dependency_scanner.get_headerunits(target, sourcebatch, modules)
    if not user_headerunits and not stl_headerunits then
       return
    end

    -- we need new group(headerunits)
    -- e.g. group(build_modules) -> group(headerunits)
    opt.rootjob = batchjobs:group_leave() or opt.rootjob
    batchjobs:group_enter(target:name() .. "/build_headerunits", {rootjob = opt.rootjob})

    local build_headerunits = function(headerunits)
        local modulesjobs = {}
        _build_headerunits(target, headerunits, table.join(opt, {
            build_headerunit = function(headerunit, key, bmifile, outputdir, build)
                local job_name = target:name() .. key
                local job = _builder(target).make_headerunit_buildjobs(target, job_name, batchjobs, headerunit, bmifile, outputdir, table.join(opt, {build = build}))
                if job then
                  modulesjobs[job_name] = job
                end
            end
        }))
        build_batchjobs_for_modules(modulesjobs, batchjobs, opt.rootjob)
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

-- generate headerunits for batchcmds
function build_headerunits_for_batchcmds(target, batchcmds, sourcebatch, modules, opt)

    local user_headerunits, stl_headerunits = dependency_scanner.get_headerunits(target, sourcebatch, modules)
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

function generate_metadata(target, modules)
    local public_modules
    for _, module in table.orderpairs(modules) do
        local _, _, cppfile = compiler_support.get_provided_module(module)
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
    runjobs(target:name() .. "_install_modules", function(index, total, jobopt)
        local module = public_modules[index]
        local name, _, cppfile = compiler_support.get_provided_module(module)
        local metafilepath = compiler_support.get_metafile(target, cppfile)
        progress.show(jobopt.progress, "${color.build.target}<%s> generating.module.metadata %s", target:name(), name)
        local metadata = _generate_meta_module_info(target, name, cppfile, module.requires)
        json.savefile(metafilepath, metadata)
    end, {comax = jobs, total = #public_modules})
end

-- flush target module mapper keys
function flush_target_module_mapper_keys(target)
    local memcache = compiler_support.memcache()
    memcache:set2(target:name(), "module_mapper_keys", nil)
end

-- get or create a target module mapper
function get_target_module_mapper(target)
    local memcache = compiler_support.memcache()
    local mapper = memcache:get2(target:name(), "module_mapper")
    if not mapper then
        mapper = {}
        memcache:set2(target:name(), "module_mapper", mapper)
    end

    -- we generate the keys map to optimise the efficiency of _is_duplicated_headerunit
    local mapper_keys = memcache:get2(target:name(), "module_mapper_keys")
    if not mapper_keys then
        mapper_keys = {}
        for _, item in pairs(mapper) do
            if item.key then
                mapper_keys[item.key] = item
            end
        end
        memcache:set2(target:name(), "module_mapper_keys", mapper_keys)
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
    local cachekey = target:name() .. module.name
    local requires = hashset.from(table.keys(module.requires or {}))
    local oldrequires = compiler_support.memcache():get2(cachekey, "oldrequires")
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
