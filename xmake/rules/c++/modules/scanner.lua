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
-- @author      ruki, Arthapz
-- @file        scanner.lua
--

-- imports
import("core.base.json")
import("core.base.hashset")
import("core.base.graph")
import("core.base.option")
import("core.base.profiler")
import("core.base.bytes")
import("async.jobgraph")
import("async.runjobs")
import("support")
import("mapper")
import("stlheaders")

function _scanner(target)
    return support.import_implementation_of(target, "scanner")
end

function _parse_meta_info(target, metafile)

    profiler.enter(target:fullname(), "c++ modules", "scanner", "parse metainfo", metafile)
    local metadata = json.loadfile(metafile)
    if metadata.file and metadata.name then
        return metadata.file, metadata.name, metadata
    end

    local filename = path.basename(metafile)
    local metadir = path.directory(metafile)
    for _, ext in ipairs({".mpp", ".mxx", ".cppm", ".ixx"}) do
        if os.isfile(path.join(metadir, filename .. ext)) then
            filename = filename .. ext
            break
        end
    end

    local sourcecode = io.readfile(path.join(path.directory(metafile), filename))
    sourcecode = sourcecode:gsub("//.-\n", "\n")
    sourcecode = sourcecode:gsub("/%*.-%*/", "")

    local name
    for _, line in ipairs(sourcecode:split("\n", {plain = true})) do
        name = line:match("export%s+module%s+(.+)%s*;") or line:match("export%s+__preprocessed_module%s+(.+)%s*;")
        if name then
            break
        end
    end
    profiler.leave(target:fullname(), "c++ modules", "scanner", "parse metainfo", metafile)
    return filename, name, metadata
end

function _get_headerunit_bmifile(target, headerfile)
    local outputdir = support.get_outputdir(target, headerfile, {headerunit = true})
    return path.join(outputdir, path.filename(headerfile) .. support.get_bmi_extension(target))
end

function _bmifile_for(target, module)
    local bmifile = support.get_bmi_path(path.filename(module.name) .. support.get_bmi_extension(target))
    return path.join(support.get_outputdir(target, module.sourcefile, {interface = module.interface, headerunit = module.headerunit}), bmifile)
end

-- parse module dependency data
--[[
{
  "build/.objs/stl_headerunit/linux/x86_64/release/src/hello.mpp.o" = {
    requires = {
      iostream = {
        method = "include-angle",
        unique = true,
        path = "/usr/include/c++/11/iostream"
      }
    },
    provides = {
      hello = {
        bmifile = "build/.gens/stl_headerunit/linux/x86_64/release/rules/modules/cache/hello.gcm",
        sourcefile = "src/hello.mpp"
      }
    }
  },
  "build/.objs/stl_headerunit/linux/x86_64/release/src/main.cpp.o" = {
    requires = {
      hello = {
        method = "by-name",
        unique = false,
        path = "build/.gens/stl_headerunit/linux/x86_64/release/rules/modules/cache/hello.gcm"
      }
    }
  }
}]]
function _parse_moduleinfo(target, moduleinfo)
    assert(moduleinfo.version <= 1)
    local module
    local headerunitsinfo
    for _, rule in ipairs(moduleinfo.rules) do
        module = {objectfile = path.translate(rule["primary-output"]), sourcefile = moduleinfo.sourcefile}

        if rule.provides then
            -- assume rule.provides is always one element on C++
            -- @see https://www.open-std.org/jtc1/sc22/wg21/docs/papers/2022/p1689r5.html
            local provide = rule.provides and rule.provides[1]
            if provide then
                assert(provide["logical-name"])

                module.name = provide["logical-name"]
                module.sourcefile = module.sourcefile or path.normalize(provide["source-path"])
                module.headerunit = provide["is-headerunit"]
                module.interface = (not module.headerunit and provide["is-interface"] == nil) and true or provide["is-interface"]
                module.method = provide["lookup-method"] or "by-name"

                if module.headerunit then
                    local key = support.get_headerunit_key(target, module.sourcefile)
                    module.key = key
                end

                -- XMake handle bmifile so we don't need rely on compiler-module-path
                module.bmifile = _bmifile_for(target, module)
            end
        end

        if rule.requires then
            module.deps = {}
            for _, dep in ipairs(rule.requires) do
                local method = dep["lookup-method"] or "by-name"
                local name = dep["logical-name"]
                local headerunit = method:startswith("include")
                local key = headerunit and support.get_headerunit_key(target, name)
                module.deps[name] = {
                    name = name,
                    method = method,
                    headerunit = headerunit,
                    key = key,
                    unique = dep["unique-on-source-path"] or false,
                }
                if method:startswith("include") then
                    local sourcefile = dep["source-path"]
                    headerunitsinfo = headerunitsinfo or {}
                    table.insert(headerunitsinfo, {
                        version = 0,
                        revision = 0,
                        sourcefile = path.normalize(sourcefile),
                        rules = {{
                            provides = {table.join(dep, {["is-headerunit"] = true})}
                        }}
                    })
                end
            end
        end
    end
    return module, headerunitsinfo
end

-- generate edges for DAG
function _get_edges(target, nodes, modules)

  profiler.enter(target:fullname(), "c++ modules", "scanner", "get module dependency graph edges")
  local edges = {}
  local name_filemap = {}
  local deps_names = hashset.new()
  for _, node in ipairs(table.unique(nodes)) do
      local module = modules[node]
      if module.name then
          if deps_names:has(module.name) then
              raise("duplicate module name detected for \"" .. module.name .. "\"\n  <" .. target:fullname() .. "> -> " .. module.sourcefile .. "\n  <" .. target:fullname() .. "> -> " .. name_filemap[module.name])
          end
          deps_names:insert(module.name)
          name_filemap[module.name] = module.sourcefile
      elseif module.headerunit then
          deps_names:insert(module.name)
          name_filemap[module.name] = module.sourcefile
      end
      for dep_name, _ in table.orderpairs(module.deps) do
          for _, dep_node in ipairs(nodes) do
              local dep_module = modules[dep_node]
              if dep_module.name and dep_name == dep_module.name then
                  table.insert(edges, {dep_node, node})
                  break
              end
          end
      end
  end
  profiler.leave(target:fullname(), "c++ modules", "scanner", "get module dependency graph edges")
  return edges
end

-- get package modules
function _get_package_modules(target, package, opt)
    profiler.enter(target:fullname(), "c++ modules", "scanner", "get modules from package", package:name())
    opt = opt or {}
    local package_modules
    local modulesdir = path.join(package:installdir(), "modules")
    local metafiles = os.files(path.join(modulesdir, "*", "*.meta-info"))
    local jobs = jobgraph.new()
    for _, metafile in ipairs(metafiles) do
        jobs:add("job/parse_meta_file/" .. metafile, function()
            package_modules = package_modules or {}
            local modulefile, _, metadata = _parse_meta_info(target, metafile)

            local bmionly = package:libraryfiles() and true or false
            package_modules[path.join(modulesdir, modulefile)] = {defines = metadata.defines,
                                                                  undefines = metadata.undefines,
                                                                  bmionly = bmionly,
                                                                  external = opt.external and target:fullname()}
        end)
    end
    runjobs(format("parsing package %s module metafiles", package:name()), jobs, {comax = option.get("jobs") or os.default_njob()})
    profiler.leave(target:fullname(), "c++ modules", "scanner", "get modules from package", package:name())
    return package_modules
end

function _get_packages_for(target)
    local packages = {}
    for _, pkg in pairs(target:orderpkgs()) do
        packages[pkg:name()] = {pkg = pkg, external = false}
    end
    for _, dep in pairs(target:orderdeps()) do
        local dep_packages = _get_packages_for(dep)
        for pkgname, package in pairs(dep_packages) do
            packages[pkgname] = {pkg = package.pkg, external = package.external or dep}
        end
    end
    return packages
end

-- get packages modules
function _get_packages_modules(target)
    profiler.enter(target:fullname(), "c++ modules", "scanner", "get modules from package dependencies")
    -- parse all meta-info and append their informations to the package store
    local packages_modules = support.memcache():get2(target:fullname(), "cxx_packages_modules")
    if not packages_modules then
        packages_modules = {}
        local packages = _get_packages_for(target)
        for _, package in table.orderpairs(packages) do
            local package_modules = _get_package_modules(package.external or target, package.pkg, {external = package.external})
            if package_modules then
               packages_modules = packages_modules or {}
               table.join2(packages_modules, package_modules)
            end
        end
        support.memcache():set2(target:fullname(), "cxx_packages_modules", packages_modules)
    end
    profiler.leave(target:fullname(), "c++ modules", "get modules from package dependencies")
    return packages_modules
end

-- get target deps modules
function _get_targetdeps_modules(target)

    profiler.enter(target:fullname(), "c++ modules", "scanner", "get modules from target dependencies")
    local _, stdmodules_set = support.get_stdmodules(target)
    local modules
    for _, dep in ipairs(target:orderdeps()) do
        local sourcebatches = dep:sourcebatches()
        if sourcebatches and sourcebatches["c++.build.modules.scanner"] then
            local sourcebatch = sourcebatches["c++.build.modules.scanner"]
            if sourcebatch.sourcefiles then
                for _, sourcefile in ipairs(sourcebatch.sourcefiles) do
                    modules = modules or {}
                    if support.is_public(dep, sourcefile) or stdmodules_set:has(sourcefile) then
                        local _fileconfig = dep:fileconfig(sourcefile)
                        local fileconfig = {}
                        if _fileconfig then
                            fileconfig.defines = _fileconfig.defines
                            fileconfig.undefines = _fileconfig.undefines
                            fileconfig.includedirs = _fileconfig.includedirs
                        end
                        fileconfig.defines = table.join(fileconfig.defines or {}, dep:get("defines") or {})
                        fileconfig.undefines = table.join(fileconfig.undefines or {}, dep:get("undefines") or {})
                        fileconfig.includedirs = table.join(fileconfig.includedirs or {}, dep:get("includedirs") or {})
                        if not dep:is_phony() then
                            if target:namespace() == dep:namespace() then
                                fileconfig.external = dep:name()
                            else
                                fileconfig.external = dep:fullname()
                            end
                            fileconfig.bmionly = not dep:is_moduleonly()
                        end
                        if not modules[sourcefile] then
                            modules[sourcefile] = fileconfig
                        end
                    end
                end
            end
        end
    end
    profiler.leave(target:fullname(), "c++ modules", "scanner", "get modules from target dependencies")
    return modules
end

-- check if flags are compatible for module reuse
function _are_flags_compatible(target, other, sourcefile)

    local compinst1 = target:compiler("cxx")
    local flags1 = compinst1:compflags({sourcefile = sourcefile, target = target, sourcekind = "cxx"})

    local compinst2 = other:compiler("cxx")
    local flags2 = compinst2:compflags({sourcefile = sourcefile, target = other, sourcekind = "cxx"})

    local strip_defines = not target:policy("build.c++.modules.reuse.strict") and
                                   not target:policy("build.c++.modules.tryreuse.discriminate_on_defines")

    -- strip unrelevent flags
    flags1 = support.strip_flags(target, flags1, {strip_defines = strip_defines})
    flags2 = support.strip_flags(target, flags2, {strip_defines = strip_defines})

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

function get_basegroup_for(target)
    return target:fullname() .. "/modules"
end

function get_computedagjob_for(target)
    return get_basegroup_for(target) .. "/computedag"
end

function get_scangroup_for(target)
    return get_basegroup_for(target) .. "/scan"
end

function get_scanfilejob_for(target, sourcefile)
    return get_scangroup_for(target) .. "/" .. sourcefile
end

function get_parsegroup_for(target)
    return get_basegroup_for(target) .. "/parse"
end

function get_parsefilejob_for(target, sourcefile)
    return get_parsegroup_for(target) .. "/" .. sourcefile
end

-- patch sourcebatch
function _patch_sourcebatch(target, sourcebatch)

    local memcache = support.memcache()
    -- target deps modules
    local depsmodules = _get_targetdeps_modules(target) or {}

    -- package modules
    local pkgmodules = _get_packages_modules(target) or {}

    local externalmodules = table.join(depsmodules, pkgmodules)
    local keys = #sourcebatch.sourcefiles > 0 and table.concat(sourcebatch.sourcefiles) or " "
    keys = keys .. (#externalmodules > 0 and table.concat(table.orderkeys(externalmodules)) or " ")
    local md5sum = hash.md5(bytes(keys))
    local localcache = support.localcache()
    local cached_patched_sourcebatch = localcache:get2(target:fullname(), "patched_sourcebatch")
    if not cached_patched_sourcebatch or md5sum ~= cached_patched_sourcebatch.md5sum then
        local reuse = target:policy("build.c++.modules.reuse") or
                      target:policy("build.c++.modules.tryreuse")
        local reused = {}
        for sourcefile, fileconfig in pairs(externalmodules) do
            if reuse and fileconfig.external then
                local nocheck = target:policy("build.c++.modules.reuse.nocheck")
                local strict = target:policy("build.c++.modules.reuse.strict") or
                               target:policy("build.c++.modules.tryreuse.discriminate_on_defines")
                local dep = target:dep(fileconfig.external)
                assert(dep, "dep target <%s> for <%s> not found", fileconfig.external, target:fullname())

                local can_reuse = nocheck or _are_flags_compatible(target, dep, sourcefile, {strict = strict})
                if can_reuse then
                    local _reused, from = support.is_reused(dep, sourcefile)
                    if _reused then
                        support.set_reused(target, from, sourcefile)
                    else
                        support.set_reused(target, dep, sourcefile)
                    end
                    table.insert(reused, sourcefile)
                    if dep:is_moduleonly() then
                        dep:data_set("cxx.modules.reused", true)
                    end
                end
            end
            table.insert(sourcebatch.sourcefiles, sourcefile)
            target:fileconfig_add(sourcefile, fileconfig)
            memcache:set2(target:fullname(), "modules.changed", true)
        end
        sourcebatch.sourcekind = "cxx"
        sourcebatch.objectfiles = {}
        sourcebatch.dependfiles = {}
        for _, sourcefile in ipairs(sourcebatch.sourcefiles) do
            local reused, from = support.is_reused(target, sourcefile)
            local _target = reused and from or target
            local objectfile = _target:objectfile(sourcefile)
            local dependfile = _target:dependfile(sourcefile or objectfile)
            table.insert(sourcebatch.dependfiles, dependfile)
        end
        localcache:set2(target:fullname(), "patched_sourcebatch", {sourcefiles = sourcebatch.sourcefiles, dependfiles = sourcebatch.dependfiles, reused = reused, md5sum = md5sum})
    else
        local reused = hashset.from(cached_patched_sourcebatch.reused)
        for sourcefile, fileconfig in pairs(externalmodules) do
            if reused:has(sourcefile) then
                local dep = target:dep(fileconfig.external)
                assert(dep, "dep target <%s> for <%s> not found", fileconfig.external, target:fullname())
                local _reused, from = support.is_reused(dep, sourcefile)
                if _reused then
                    support.set_reused(target, from, sourcefile)
                else
                    support.set_reused(target, dep, sourcefile)
                end
                if dep:is_moduleonly() then
                    dep:data_set("cxx.modules.reused", true)
                end
            end
            target:fileconfig_add(sourcefile, fileconfig)
        end
        sourcebatch.sourcekind = "cxx"
        sourcebatch.objectfiles = {}
        sourcebatch.dependfiles = {}
        for _, sourcefile in ipairs(sourcebatch.sourcefiles) do
            local reused, from = support.is_reused(target, sourcefile)
            local _target = reused and from or target
            local objectfile = _target:objectfile(sourcefile)
            local dependfile = _target:dependfile(objectfile)
            table.insert(sourcebatch.dependfiles, dependfile)
            sourcebatch.sourcekind = "cxx"
            sourcebatch.dependfiles= cached_patched_sourcebatch.dependfiles
            sourcebatch.sourcefiles = cached_patched_sourcebatch.sourcefiles
            sourcebatch.objectfiles= cached_patched_sourcebatch.objectfiles
        end
    end
end

function _do_computedag(target, modules, sourcebatch)

    profiler.enter(target:fullname(), "c++ modules", "scanner", "compute dag")
    local localcache = support.localcache()
    local memcache = support.memcache()
    local changed = memcache:get2(target:fullname(), "modules.changed")
    if changed then
        localcache:set2(target:fullname(), "c++.modules", modules)
        mapper.feed(target, modules, sourcebatch.sourcefiles)
        -- check if a dependency is missing
        local modules_names = hashset.from(table.keys(mapper.get_mapper_for(target)))
        for _, module in pairs(modules) do
            for dep_name, dep in pairs(module.deps) do
                if dep.method == "by-name" then
                    if not modules_names:has(dep_name) then
                        if option.get("diagnosis") then
                            print("parsing:", target:fullname(), "\nmodules:", modules or {})
                        end
                        raise("<%s> missing %s dependency for module %s", target:fullname(), dep_name, module.name or module.sourcefile)
                    end
                end
            end
        end
        -- steal from c++.build sourcebatch named modules with cpp extensions
        local sourcebatches = target:sourcebatches()
        if sourcebatches and sourcebatches["c++.build"] then
            local cxx_sourcebatch = sourcebatches["c++.build"]
            cxx_sourcebatch.sourcefiles = {}
            cxx_sourcebatch.dependfiles = {}
            cxx_sourcebatch.objectfiles = {}
            for _, sourcefile in ipairs(sourcebatch.sourcefiles) do
                local module = modules[sourcefile]
                local insert = true
                if module then
                    insert = not module.name
                end

                if insert then
                    table.insert(cxx_sourcebatch.sourcefiles, sourcefile)
                    local objectfile = target:objectfile(sourcefile)
                    table.insert(cxx_sourcebatch.dependfiles, target:dependfile(objectfile))
                    table.insert(cxx_sourcebatch.objectfiles, objectfile)
                end
            end
            localcache:set2(target:fullname(), "c++.build.sourcebatch", cxx_sourcebatch)
        end
    else
        modules = get_modules(target)
        local cxx_sourcebatch_cached = localcache:get2(target:fullname(), "c++.build.sourcebatch")
        if cxx_sourcebatch_cached then
            local cxx_sourcebatch = target:sourcebatches()["c++.build"]
            cxx_sourcebatch.sourcefiles = cxx_sourcebatch_cached.sourcefiles
            cxx_sourcebatch.dependfiles = cxx_sourcebatch_cached.dependfiles
            cxx_sourcebatch.objectfiles = cxx_sourcebatch_cached.objectfiles
        end
    end

    -- sort modules
    sort_modules_by_dependencies(target, modules)

    -- save cache if all other target finished
    local targets = memcache:get("targets")
    targets[target:fullname()].finished_parsing = true

    local save_cache = true
    for _, _target in pairs(targets) do
        if not _target.finished_parsing then
            save_cache = false
            break
        end
    end
    if save_cache then
        localcache:save()
    end
    profiler.leave(target:fullname(), "c++ modules", "scanner", "compute dag")
    -- jobgraph:dump()
end

function _do_scan(target, sourcefile, opt)
    profiler.enter(target:fullname(), "c++ modules", "scanner", "scan dependencies for", sourcefile)
    local changed = _scanner(target).scan_dependency_for(target, sourcefile, opt)
    if changed or not support.localcache():get2(target:fullname(), "module_mapper") then
        support.memcache():set2(target:fullname(), "modules.changed", true)
    end
    profiler.leave(target:fullname(), "c++ modules", "scanner", "scan dependencies for", sourcefile)
end

-- scan module dependencies
function _schedule_module_dependencies_scan(target, jobgraph, sourcebatch)

    profiler.enter(target:fullname(), "c++ modules", "scanner", "schedule moduleinfo scanning, parsing and dag computation")
    -- if XMAKE_IN_COMPILE_COMMANDS_PROJECT_GENERATOR is set, then we can just reuse scan artifacts from build
    if not os.getenv("XMAKE_IN_COMPILE_COMMANDS_PROJECT_GENERATOR") or not support.localcache():get2(target:fullname(), "c++.modules") then
        local memcache = support.memcache()
        local scangroup = get_scangroup_for(target)
        local has_scanjob = false
        jobgraph:group(scangroup, function()
            for _, sourcefile in ipairs(sourcebatch.sourcefiles) do
                local reused, _ = support.is_reused(target, sourcefile)
                if not reused then
                    local scanfilejob = get_scanfilejob_for(target, sourcefile)
                    if not jobgraph:has(scanfilejob) then
                        has_scanjob = true
                        jobgraph:add(scanfilejob, function(_, _, opt)
                            _do_scan(target, sourcefile, opt)
                        end)
                    end
                end
            end
        end)
        local modules
        local parsegroup = get_parsegroup_for(target)
        jobgraph:group(parsegroup, function()
            for _, sourcefile in ipairs(sourcebatch.sourcefiles) do
                local parsefilejob = get_parsefilejob_for(target, sourcefile)
                if not jobgraph:has(parsefilejob) then
                    jobgraph:add(parsefilejob, function(_, _, opt)
                        local changed = memcache:get2(target:fullname(), "modules.changed")
                        if changed then
                            modules = modules or {}
                            local moduleinfo = support.load_moduleinfo(target, sourcefile)
                            local module, headerunitsinfo = _parse_moduleinfo(target, moduleinfo)
                            modules[module.sourcefile] = module
                            for _, headerunitinfo in ipairs(headerunitsinfo) do
                                local headerunit = _parse_moduleinfo(target, headerunitinfo)
                                local key = headerunit.sourcefile .. headerunit.key
                                if not modules[key] then
                                    modules[key] = table.clone(headerunit)
                                    modules[key].name = headerunit.sourcefile
                                end
                                local name = headerunit.name .. headerunit.key
                                modules[name] = headerunit
                                modules[name].alias = true
                            end
                        end
                    end)
                    local reused, from = support.is_reused(target, sourcefile)
                    if reused then
                        local scanfilejob = get_scanfilejob_for(from, sourcefile)
                        if jobgraph:has(scanfilejob) then
                            jobgraph:add_orders(scanfilejob, parsefilejob)
                        else
                            local jobdeps = memcache:get2(from:fullname(), "jobdeps") or {}
                            jobdeps.parsefile = jobdeps.parsefile or {}
                            jobdeps.parsefile[parsefilejob] = scanfilejob
                            memcache:set2(from:fullname(), "jobdeps", jobdeps)
                        end
                    end
                end
            end
        end)
        local computedagjob = get_computedagjob_for(target)
        jobgraph:add(computedagjob, function ()
            _do_computedag(target, modules, sourcebatch)
        end)
        if has_scanjob then
            jobgraph:add_orders(scangroup, parsegroup)
        end
        jobgraph:add_orders(parsegroup, computedagjob)
        local jobdeps = memcache:get2(target:fullname(), "jobdeps")
        if jobdeps then
            for _, computedag in ipairs(jobdeps.computedag) do
                if jobgraph:has(computedag) then
                    jobgraph:add_orders(computedagjob, computedag)
                end
            end
            for from, to in pairs(jobdeps.parsefile) do
                if jobgraph:has(to) then
                    jobgraph:add_orders(to, from)
                end
            end
        end

        for _, dep in ipairs(target:orderdeps()) do
            local dep_computedagjob = get_computedagjob_for(dep)
            if jobgraph:has(dep_computedagjob) then
                jobgraph:add_orders(dep_computedagjob, computedagjob)
            else
                local jobdeps = memcache:get2(dep:fullname(), "jobdeps") or {}
                jobdeps.computedag = jobdeps.computedag or {}
                table.insert(jobdeps.computedag, computedagjob)
                memcache:set2(dep:fullname(), "jobdeps", jobdeps)
            end
        end
    end
    profiler.leave(target:fullname(), "c++ modules", "scanner", "schedule moduleinfo scanning, parsing and dag computation")
end

-- get headerunits info
function sort_headerunits(target, headerunits)
    profiler.enter(target:fullname(), "c++ modules", "scanner", "sort headerunits")
    local _headerunits
    local stl_headerunits
    for _, headerunit in ipairs(headerunits) do
        local module = mapper.get(target, headerunit)
        if stlheaders.is_stlheader(path.filename(module.name)) then
            stl_headerunits = stl_headerunits or {}
            table.insert(stl_headerunits, headerunit)
        else
            _headerunits = _headerunits or {}
            table.insert(_headerunits, headerunit)
        end
    end
    profiler.leave(target:fullname(), "c++ modules", "scanner", "sort headerunits")
    return _headerunits, stl_headerunits
end

-- https://www.open-std.org/jtc1/sc22/wg21/docs/papers/2022/p1689r5.html
--[[
{
  "version": 1,
  "revision": 0,
  "rules": [
    {
      "primary-output": "use-header.mpp.o",
      "requires": [
        {
          "logical-name": "<header.hpp>",
          "source-path": "/path/to/found/header.hpp",
          "unique-on-source-path": true,
          "lookup-method": "include-angle"
        }
      ]
    },
    {
      "primary-output": "header.hpp.bmi",
      "provides": [
        {
          "logical-name": "header.hpp",
          "source-path": "/path/to/found/header.hpp",
          "unique-on-source-path": true,
        }
      ]
    }
  ]
}]]
function fallback_generate_dependencies(target, jsonfile, sourcefile, preprocess_file)

    profiler.enter(target:fullname(), "c++ modules", "fallback scanner", "scan module dependencies for", sourcefile)
    local output = {version = 1, revision = 0, rules = {}}
    local rule = {outputs = {jsonfile}}
    rule["primary-output"] = target:objectfile(sourcefile)

    local module_name_export
    local module_name_private
    local module_deps = {}
    local module_deps_set = hashset.new()
    local sourcecode = preprocess_file(sourcefile) or io.readfile(sourcefile)
    local internal = false
    sourcecode = sourcecode:gsub("//.-\n", "\n")
    sourcecode = sourcecode:gsub("/%*.-%*/", "")
    for _, line in ipairs(sourcecode:split("\n", {plain = true})) do
        if line:match("#") then
            goto continue
        end
        if not module_name_export then
            module_name_export = line:match("export%s+module%s+(.+)%s*;") or line:match("export%s+__preprocessed_module%s+(.+)%s*;")
        end
        if not module_name_private then
            module_name_private = line:match("module%s+(.+)%s*;") or line:match("__preprocessed_module%s+(.+)%s*;")
            if module_name_private then
                internal = module_name_private:find(":")
            end
        end
        local module_depname = line:match("import%s+(.+)%s*;")
        -- we need to parse module interface dep in cxx/impl_unit.cpp, e.g. hello.mpp and hello_impl.cpp
        -- @see https://github.com/xmake-io/xmake/pull/2664#issuecomment-1213167314
        if not module_depname and not support.has_module_extension(sourcefile) then
            module_depname = module_name_private
        end
        if module_depname and not module_deps_set:has(module_depname) then
            local module_dep = {}
            -- partition? import :xxx;
            if module_depname:startswith(":") then
                local module_name = (module_name_export or module_name_private or "")
                module_name = module_name:split(":")[1]
                module_dep["unique-on-source-path"] = true
                module_depname = module_name .. module_depname
            elseif module_depname:startswith("\"") then
                module_depname = module_depname:sub(2, -2)
                module_dep["lookup-method"] = "include-quote"
                module_dep["unique-on-source-path"] = true
                module_dep["source-path"] = support.find_quote_header_file(sourcefile, module_depname)
            elseif module_depname:startswith("<") then
                module_depname = module_depname:sub(2, -2)
                module_dep["lookup-method"] = "include-angle"
                module_dep["unique-on-source-path"] = true
                module_dep["source-path"] = support.find_angle_header_file(target, module_depname)
            end
            module_dep["logical-name"] = module_depname
            table.insert(module_deps, module_dep)
            module_deps_set:insert(module_depname)
        end
        ::continue::
    end

    if module_name_export or internal then
        local outputdir = support.get_outputdir(target, sourcefile, {scan = true})

        local provide = {}
        provide["logical-name"] = module_name_export or module_name_private
        provide["source-path"] = sourcefile
        provide["is-interface"] = not internal
        provide["compiled-module-path"] = path.join(outputdir, (module_name_export or module_name_private) .. support.get_bmi_extension(target))

        rule.provides = {}
        table.insert(rule.provides, provide)
    end

    rule.requires = module_deps
    table.insert(output.rules, rule)
    local jsondata = json.encode(output)
    io.writefile(jsonfile, jsondata)
    profiler.leave(target:fullname(), "c++ modules", "fallback scanner", "scan module dependencies for", sourcefile)
end

-- topological sort
function sort_modules_by_dependencies(target, modules)

    profiler.enter(target:fullname(), "c++ modules", "scanner", "compute module dependency dag")
    local memcache = support.memcache()
    local localcache = support.localcache()
    local changed = memcache:get2(target:fullname(), "modules.changed")
    local built_artifacts = localcache:get2(target:fullname(), "c++.modules.built_artifacts")
    if changed or not built_artifacts then
        local built_modules = {}
        local built_headerunits = {}
        local objectfiles = {}

        -- feed the dag
        local nodes = {}
        for node, module in pairs(modules) do
            table.insert(nodes, module.headerunit and node or module.sourcefile)
        end
        -- table.unique(nodes)
        local edges = _get_edges(target, nodes, modules)
        local dag = graph.new(true)
        for _, e in ipairs(edges) do
            dag:add_edge(e[1], e[2])
        end
        -- check if dag have dependency cycles and sort sourcefiles by dependencies
        local sourcefiles_sorted, has_cycle = dag:topo_sort()
        if has_cycle then
            local cycle = dag:find_cycle()
            if cycle then
                local names = {}
                for _, sourcefile in ipairs(cycle) do
                    local module = modules[sourcefile]
                    table.insert(names, module.name or module.sourcefile)
                end
                local module = modules[cycle[1]]
                table.insert(names, module.name or module.sourcefile)
                raise("circular modules dependency detected!\n%s", table.concat(names, "\n   -> import "))
            end
        end
        local sourcefiles_sorted_set = hashset.from(sourcefiles_sorted)
        for sourcefile, _ in pairs(modules) do
            if not sourcefiles_sorted_set:has(sourcefile) then
                table.insert(sourcefiles_sorted, sourcefile)
                sourcefiles_sorted_set:insert(sourcefile)
            end
        end
        -- prepare objectfiles list built by the target
        local culleds
        for _, sourcefile in ipairs(sourcefiles_sorted) do
            local module = mapper.get(target, sourcefile)
            local name = module.name
            local is_named = name ~= nil
            local sort = (is_named and (module.sourcealias or not module.alias)) or not is_named
            if sort then
                local insert = false
                local reused, from = support.is_reused(target, sourcefile)

                if is_named and not module.headerunit then -- named modules
                    insert = not support.can_be_culled(target, sourcefile)

                    -- if module is cullable (culling policy enabled and not a public module), try to cull
                    if not insert then
                        local edges = dag:adjacent_edges(sourcefile)
                        if edges then
                            for _, edge in ipairs(edges) do
                                if edge:to() ~= sourcefile and sourcefiles_sorted_set:has(edge:to()) then
                                    insert = true
                                    break
                                end
                            end
                        end
                    end
                else -- regular translation unit with import statements, always inserted
                    insert = true
                end

                if insert then
                    if reused then
                        if not support.is_bmionly(target, sourcefile) or module.name == "std" or module.name == "std.compat" then
                            local objectfile = from:objectfile(sourcefile)
                            table.insert(objectfiles, tostring(objectfile))
                        end
                    elseif module.headerunit then
                        table.insert(built_headerunits, sourcefile)
                    else
                        table.insert(built_modules, sourcefile)
                        -- insert objectfile if module named and is not imported from a static / shared library or if from a C++ file with a c++ module extension
                        -- if not so objectfile will be handled by c++.build rule
                        if not support.is_bmionly(target, sourcefile) and (support.has_module_extension(sourcefile) or is_named) then
                            local objectfile = target:objectfile(sourcefile)
                            table.insert(objectfiles, tostring(objectfile))
                        end
                   end
                elseif support.is_external(target, sourcefile) or module.headerunit or name == "std" or name == "std.compat" then
                else
                    sourcefiles_sorted_set:remove(sourcefile)
                    culleds = culleds or {}
                    culleds[target:fullname()] = culleds[target:fullname()] or {}
                    table.insert(culleds[target:fullname()], format("%s -> %s", name, sourcefile))
                end
            end
        end

        -- if some named modules has been culled, notify the user
        if culleds then
            if option.get("verbose") then
                local culled_strs = {}
                for target_name, m in pairs(culleds) do
                    table.insert(culled_strs, format("%s:\n        %s", target_name, table.concat(m, "\n        ")))
                end
                wprint("some modules have got culled, because it is not consumed by its target nor flagged as a public module with add_files(\"xxx.mpp\", {public = true})\n    %s",
                       table.concat(culled_strs, "\n    "))
            else
                wprint("some modules have got culled, use verbose (-v) mode to more informations")
            end
        end
        built_headerunits = table.unique(built_headerunits)

        built_artifacts = {modules = built_modules, headerunits = built_headerunits, objectfiles = objectfiles}
        localcache:set2(target:fullname(), "c++.modules.built_artifacts", built_artifacts)
        memcache:set2(target:fullname(), "modules.changed", false)
    end
    assert(built_artifacts, "shouldn't assert here, please open an issue")
    profiler.leave(target:fullname(), "c++ modules", "scanner", "compute module dependency dag")
    return built_artifacts.modules, built_artifacts.headerunits, built_artifacts.objectfiles
end

function get_modules(target)
    local modules = support.localcache():get2(target:fullname(), "c++.modules")
    assert(modules, "no modules!")
    return modules
end

function after_scan(target)
    local sourcebatches = target:sourcebatches()
    local sourcebatch_builder = sourcebatches and sourcebatches["c++.build.modules.builder"]
    local sourcebatch_scanner = sourcebatches and sourcebatches["c++.build.modules.scanner"]
    if sourcebatch_scanner then
        sourcebatch_scanner.sourcefiles = {}
    end
    if sourcebatch_builder then
        sourcebatch_builder.sourcefiles = {}
        sourcebatch_builder.dependfiles = {}
        sourcebatch_builder.objectfiles = {}
    end
    if target:data("cxx.has_modules") then
        if target:is_moduleonly() or target:is_phony() then
            return
        end
        local compile_commands = os.getenv("XMAKE_IN_PROJECT_GENERATOR") and os.getenv("XMAKE_IN_COMPILE_COMMANDS_PROJECT_GENERATOR")
        local need_objectfiles = not os.getenv("XMAKE_IN_PROJECT_GENERATOR") or compile_commands
        if need_objectfiles then
            local modules = get_modules(target)
            local _, _, objectfiles = sort_modules_by_dependencies(target, modules)
            assert(sourcebatch_builder)
            sourcebatch_builder.objectfiles = objectfiles
        end
    end
end

function main(target, jobgraph, sourcebatch)
    profiler.enter(target:fullname(), "c++ modules", "scanner", "scan")
    local compile_commands = os.getenv("XMAKE_IN_PROJECT_GENERATOR") and os.getenv("XMAKE_IN_COMPILE_COMMANDS_PROJECT_GENERATOR")
    if target:data("cxx.has_modules") and (not os.getenv("XMAKE_IN_PROJECT_GENERATOR") or compile_commands) then
        _patch_sourcebatch(target, sourcebatch)
        _schedule_module_dependencies_scan(target, jobgraph, sourcebatch)
    end
    profiler.leave(target:fullname(), "c++ modules", "scanner", "scan")
end
