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
import("private.async.buildjobs")
import("core.tool.compiler")
import("core.project.config")
import("core.project.depend")
import("utils.progress")
import("compiler_support")
import("dependency_scanner")

-- build target modules
function _build_modules(target, sourcebatch, modules, opt)
    local objectfiles = dependency_scanner.sort_modules_by_dependencies(sourcebatch.objectfiles, modules)

    _builder(target).populate_module_map(target, modules)

    -- build modules
    for _, objectfile in ipairs(objectfiles) do
        local module = modules[objectfile]
        if not module then
            goto CONTINUE
        end

        local name, provide, cppfile = compiler_support.get_provided_module(module)
        cppfile = cppfile or module.cppfile

        local fileconfig = target:fileconfig(cppfile)
        local bmifile = provide and compiler_support.get_bmi_path(provide.bmi)
        local build = _should_build(target, cppfile, bmifile, objectfile, module.requires)

        -- add objectfile if module is not from external dep
        if not (fileconfig and fileconfig.external) then
            target:add("objectfiles", objectfile)
        end

        -- needed to detect rebuild of dependencies
        if provide then
            compiler_support.memcache():set2(target:name(), name, build)
        end

        local deps = {}
        for _, dep in ipairs(table.keys(module.requires or {})) do
            table.insert(deps, opt.batchjobs and target:name() .. dep or dep)
        end

        opt.build_module(deps, build, module, name, provide, objectfile, cppfile, fileconfig)

        ::CONTINUE::
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
        local build = _should_build(target, headerunit.path, bmifile, nil, nil, {key = key, headerunit = true})

        compiler_support.memcache():set2(target:name(), key, build)

        opt.build_headerunit(headerunit, key, bmifile, outputdir, build)
    end
end

-- should we build this module or headerunit ?
function _should_build(target, sourcefile, bmifile, objectfile, requires, opt)

    -- force rebuild a module if any of its module dependency is rebuilt
    if requires then
        for required, _ in pairs(requires) do
            local m = get_from_target_mapper(target, required)
            if m then
                local rebuild = compiler_support.memcache():get2(target:name(), m.key)
                if rebuild then
                    return true
                end
            end
        end
    end

    -- or rebuild it if the file changed for headerunit and namedmodules
    if compiler_support.has_module_extension(sourcefile) or (opt and opt.headerunit) then
        local dryrun = option.get("dry-run")
        local compinst = compiler.load("cxx", {target = target})
        local compflags = compinst:compflags({sourcefile = sourcefile, target = target})

        local dependfile = target:dependfile(bmifile or objectfile)
        local dependinfo = target:is_rebuilt() and {} or (depend.load(dependfile) or {})

        -- need build this object?
        local depvalues = {compinst:program(), compflags}
        local lastmtime = os.isfile(bmifile or objectfile) and os.mtime(dependfile) or 0

        if dryrun or depend.is_changed(dependinfo, {lastmtime = lastmtime, values = depvalues}) then
            return true
        end
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
        for _name, _ in pairs(requires) do
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

function _is_duplicated_headerunit(target, headerunit)
    local mapper = get_target_module_mapper(target)
    local key = hash.md5(path.normalize(headerunit.path))

    -- for _, mapped in pairs(mapper) do
    --     print("CHECK", mapped.key, key)
    --     if mapped.key == key then
    --         return true
    --     end
    -- end

    return false
end

function _builder(target)

    local cachekey = tostring(target)
    local builder = compiler_support.memcache():get2("builder", cachekey)
    if builder == nil then
        if target:has_tool("cxx", "clang", "clangxx") then
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

-- build batchjobs for modules
function build_batchjobs_for_modules(modules, batchjobs, rootjob)
    return buildjobs(modules, batchjobs, rootjob)
end

-- build modules for batchjobs
function build_modules_for_batchjobs(target, batchjobs, sourcebatch, modules, opt)

    opt.rootjob = batchjobs:group_leave() or opt.rootjob
    batchjobs:group_enter(target:name() .. "/build_modules", {rootjob = opt.rootjob})

    local modulesjobs = {}

    _build_modules(target, sourcebatch, modules, table.join(opt, {
       build_module = function(deps, build, module, name, provide, objectfile, cppfile, fileconfig)
        local job_name = name and target:name() .. name or cppfile

        modulesjobs[job_name] = _builder(target).make_module_build_job(target, batchjobs, job_name, deps, {build = build, module = module, objectfile = objectfile, cppfile = cppfile})

        if provide and fileconfig and fileconfig.public then
            batchjobs:addjob(name .. "_metafile", function(index, total)
                local metafilepath = compiler_support.get_metafile(target, cppfile)
                depend.on_changed(function()
                    progress.show((index * 100) / total, "${color.build.target}<%s> generating.module.metadata %s", target:name(), name)
                    local metadata = _generate_meta_module_info(target, name, cppfile, module.requires)
                    json.savefile(metafilepath, metadata)
                end, {dependfile = target:dependfile(metafilepath), files = {cppfile}, changed = target:is_rebuilt()})
            end, {rootjob = opt.rootjob})
        end
      end
    }))

    -- build batchjobs for modules
    build_batchjobs_for_modules(modulesjobs, batchjobs, opt.rootjob)
end

-- build modules for batchcmds
function build_modules_for_batchcmds(target, batchcmds, sourcebatch, modules, opt)

    local depmtime = 0
    opt.progress = opt.progress or 0

    -- build modules
    _build_modules(target, sourcebatch, modules, table.join(opt, {
       build_module = function(_, build, module, name, provide, objectfile, cppfile, fileconfig)
          depmtime = math.max(depmtime, _builder(target).make_module_build_cmds(target, batchcmds, {build = build, module = module, cppfile = cppfile, objectfile = objectfile, progress = opt.progress}))

          if provide and fileconfig and fileconfig.public then
              local metafilepath = compiler_support.get_metafile(target, cppfile)
              depend.on_changed(function()
                  progress.show(opt.progress, "${color.build.target}<%s> generating.module.metadata %s", target:name(), name)
                  local metadata = _generate_meta_module_info(target, name, cppfile, module.requires)
                  json.savefile(metafilepath, metadata)
              end, {dependfile = target:dependfile(metafilepath), files = {cppfile}, changed = target:is_rebuilt()})
          end
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
                local job = _builder(target).make_headerunit_build_job(target, job_name, batchjobs, headerunit, bmifile, outputdir, table.join(opt, {build = build}))
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
                depmtime = math.max(depmtime, _builder(target).make_headerunit_build_cmds(target, batchcmds, headerunit, bmifile, outputdir, table.join({build = build}, opt)))
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

-- get or create a target module mapper
function get_target_module_mapper(target)

    opt = opt or {}
    local memcache = compiler_support.memcache()
    local mapper = memcache:get2(target:name(), "module_mapper")
    if not mapper then
        mapper = {}
        memcache:set2(target:name(), "module_mapper", mapper)
    end

    return mapper
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
    mapper[name] = {name = name, key = name, bmi = bmifile, sourcefile = sourcefile, opt = opt}
end

-- add a headerunit to target mapper
function add_headerunit_to_target_mapper(target, headerunit, bmifile)
    local mapper = get_target_module_mapper(target)
    mapper[headerunit.name] = {name = headerunit.name, key = path.normalize(headerunit.path), headerunit = headerunit, bmi = bmifile}
    return _is_duplicated_headerunit(target, headerunit)
end

