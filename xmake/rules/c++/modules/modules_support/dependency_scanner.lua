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
-- @file        dependency_scanner.lua
--

-- imports
import("core.base.json")
import("core.base.hashset")
import("core.base.graph")
import("core.base.option")
import("async.runjobs")
import("compiler_support")
import("stl_headers")

function _dependency_scanner(target)
    local cachekey = tostring(target)
    local dependency_scanner = compiler_support.memcache():get2("dependency_scanner", cachekey)
    if dependency_scanner == nil then
        if target:has_tool("cxx", "clang", "clangxx", "clang_cl") then
            dependency_scanner = import("clang.dependency_scanner", {anonymous = true})
        elseif target:has_tool("cxx", "gcc", "gxx") then
            dependency_scanner = import("gcc.dependency_scanner", {anonymous = true})
        elseif target:has_tool("cxx", "cl") then
            dependency_scanner = import("msvc.dependency_scanner", {anonymous = true})
        else
            local _, toolname = target:tool("cxx")
            raise("compiler(%s): does not support c++ module!", toolname)
        end
        compiler_support.memcache():set2("dependency_scanner", cachekey, dependency_scanner)
    end
    return dependency_scanner
end

function _parse_meta_info(target, metafile)
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
    return filename, name, metadata
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
        bmi = "build/.gens/stl_headerunit/linux/x86_64/release/rules/modules/cache/hello.gcm",
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
function _parse_dependencies_data(target, moduleinfos)
    local modules
    for _, moduleinfo in ipairs(moduleinfos) do
        assert(moduleinfo.version <= 1)
        for _, rule in ipairs(moduleinfo.rules) do
            modules = modules or {}
            local m = {}
            if rule.provides then
                for _, provide in ipairs(rule.provides) do
                    m.provides = m.provides or {}
                    assert(provide["logical-name"])
                    local bmifile = provide["compiled-module-path"]
                    -- try to find the compiled module path in outputs filed (MSVC doesn't generate compiled-module-path)
                    if not bmifile then
                        for _, output in ipairs(rule.outputs) do
                            if output:endswith(compiler_support.get_bmi_extension(target)) then
                                bmifile = output
                                break
                            end
                        end

                        -- we didn't found the compiled module path, so we assume it
                        if not bmifile then
                            local name = provide["logical-name"] .. compiler_support.get_bmi_extension(target)
                            -- partition ":" character is invalid path character on windows
                            -- @see https://github.com/xmake-io/xmake/issues/2954
                            name = name:replace(":", "-")
                            bmifile = path.join(compiler_support.get_outputdir(target,  name), name)
                        end
                    end
                    m.provides[provide["logical-name"]] = {
                        bmi = bmifile,
                        sourcefile = moduleinfo.sourcefile,
                        interface = provide["is-interface"]
                    }
                end
            else
                m.cppfile = moduleinfo.sourcefile
            end
            assert(rule["primary-output"])
            modules[path.translate(rule["primary-output"])] = m
        end
    end

    for _, moduleinfo in ipairs(moduleinfos) do
        for _, rule in ipairs(moduleinfo.rules) do
            local m = modules[path.translate(rule["primary-output"])]
            for _, r in ipairs(rule.requires) do
                m.requires = m.requires or {}
                local p = r["source-path"]
                if not p then
                    for _, dependency in pairs(modules) do
                        if dependency.provides and dependency.provides[r["logical-name"]] then
                            p = dependency.provides[r["logical-name"]].bmi
                            break
                        end
                    end
                end
                m.requires[r["logical-name"]] = {
                    method = r["lookup-method"] or "by-name",
                    path = p and path.translate(p) or nil,
                    unique = r["unique-on-source-path"] or false
                }
            end
        end
    end
    return modules
end

-- generate edges for DAG
function _get_edges(nodes, modules)
  local edges = {}
  local module_names = {}
  local name_filemap = {}
  local named_module_names = hashset.new()
  for _, node in ipairs(table.unique(nodes)) do
      local module = modules[node]
      local module_name, _, cppfile = compiler_support.get_provided_module(module)
      if module_name then
          if named_module_names:has(module_name) then
              raise("duplicate module name detected \"" .. module_name .. "\"\n    -> " .. cppfile .. "\n    -> " .. name_filemap[module_name])
          end
          named_module_names:insert(module_name)
          name_filemap[module_name] = cppfile
      end
      if module.requires then
          for required_name, _ in table.orderpairs(module.requires) do
              for _, required_node in ipairs(nodes) do
                  local name, _, _ = compiler_support.get_provided_module(modules[required_node])
                  if name and name == required_name then
                      table.insert(edges, {required_node, node})
                  end
              end
          end
      end
  end
  return edges
end

function _get_package_modules(target, package, opt)
    local package_modules

    local modulesdir = path.join(package:installdir(), "modules")
    local metafiles = os.files(path.join(modulesdir, "*", "*.meta-info"))
    for _, metafile in ipairs(metafiles) do
        package_modules = package_modules or {}
        local modulefile, name, metadata = _parse_meta_info(target, metafile)
        local moduleonly = not package:libraryfiles()
        package_modules[name] = {file = path.join(modulesdir, modulefile), metadata = metadata, external = {moduleonly = moduleonly}}
    end

    return package_modules
end

-- generate dependency files
function _generate_dependencies(target, sourcebatch, opt)
    local changed = false
    if opt.batchjobs then
        local jobs = option.get("jobs") or os.default_njob()
        runjobs(target:name() .. "_module_dependency_scanner", function(index) 
            local sourcefile = sourcebatch.sourcefiles[index]
            changed = _dependency_scanner(target).generate_dependency_for(target, sourcefile, opt) or changed
        end, {comax = jobs, total = #sourcebatch.sourcefiles})
    else
        for _, sourcefile in ipairs(sourcebatch.sourcefiles) do
            changed = _dependency_scanner(target).generate_dependency_for(target, sourcefile, opt) or changed
        end
    end
    return changed
end
-- get module dependencies
function get_module_dependencies(target, sourcebatch, opt)
    local cachekey = target:name() .. "/" .. sourcebatch.rulename
    local modules = compiler_support.memcache():get2("modules", cachekey)
    if modules == nil then
        modules = compiler_support.localcache():get2("modules", cachekey)
        opt.progress = opt.progress or 0
        local changed = _generate_dependencies(target, sourcebatch, opt)
        if changed or modules == nil then
            local moduleinfos = compiler_support.load_moduleinfos(target, sourcebatch)
            modules = _parse_dependencies_data(target, moduleinfos)
            compiler_support.localcache():set2("modules", cachekey, modules)
            compiler_support.localcache():save()
        end
        compiler_support.memcache():set2("modules", cachekey, modules)
    end
    return modules
end

-- get headerunits info
function get_headerunits(target, sourcebatch, modules)
    local headerunits
    local stl_headerunits
    for _, objectfile in ipairs(sourcebatch.objectfiles) do
        local m = modules[objectfile]
        if m then
            for name, r in pairs(m.requires) do
                if r.method ~= "by-name" then
                    local unittype = r.method == "include-angle" and ":angle" or ":quote"
                    if stl_headers.is_stl_header(name) then
                        stl_headerunits = stl_headerunits or {}
                        if not table.find_if(stl_headerunits, function(i, v) return v.name == name end) then
                            table.insert(stl_headerunits, {name = name, path = r.path, type = unittype, unique = r.unique})
                        end
                    else
                        headerunits = headerunits or {}
                        if not table.find_if(headerunits, function(i, v) return v.name == name end) then
                            table.insert(headerunits, {name = name, path = r.path, type = unittype, unique = r.unique})
                        end
                    end
                end
            end
        end
    end
    return headerunits, stl_headerunits
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
        if not module_depname and not compiler_support.has_module_extension(sourcefile) then
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
                module_dep["source-path"] = compiler_support.find_quote_header_file(target, sourcefile, module_depname)
            elseif module_depname:startswith("<") then
                module_depname = module_depname:sub(2, -2)
                module_dep["lookup-method"] = "include-angle"
                module_dep["unique-on-source-path"] = true
                module_dep["source-path"] = compiler_support.find_angle_header_file(target, module_depname)
            end
            module_dep["logical-name"] = module_depname
            table.insert(module_deps, module_dep)
            module_deps_set:insert(module_depname)
        end
        ::continue::
    end

    if module_name_export or internal then
        local outputdir = compiler_support.get_outputdir(target, sourcefile)

        local provide = {}
        provide["logical-name"] = module_name_export or module_name_private
        provide["source-path"] = sourcefile
        provide["is-interface"] = not internal
        provide["compiled-module-path"] = path.join(outputdir, (module_name_export or module_name_private) .. compiler_support.get_bmi_extension(target))

        rule.provides = {}
        table.insert(rule.provides, provide)
    end

    rule.requires = module_deps
    table.insert(output.rules, rule)
    local jsondata = json.encode(output)
    io.writefile(jsonfile, jsondata)
end

-- extract packages modules dependencies
function get_all_packages_modules(target, opt)

    -- parse all meta-info and append their informations to the package store
    local packages = target:pkgs() or {}
    for _, deps in ipairs(target:orderdeps()) do
        table.join2(packages, deps:pkgs())
    end

    local packages_modules
    for _, package in table.orderpairs(packages) do
        local package_modules = _get_package_modules(target, package, opt)
        if package_modules then
           packages_modules = packages_modules or {}
           table.join2(packages_modules, package_modules)
        end
    end
    return packages_modules
end

-- topological sort
function sort_modules_by_dependencies(target, objectfiles, modules, opt)
    local build_objectfiles = {}
    local link_objectfiles = {}
    local edges = _get_edges(objectfiles, modules)
    local dag = graph.new(true)
    for _, e in ipairs(edges) do
        dag:add_edge(e[1], e[2])
    end
    local cycle = dag:find_cycle()
    if cycle then
        local names = {}
        for _, objectfile in ipairs(cycle) do
            local name, _, cppfile = compiler_support.get_provided_module(modules[objectfile])
            table.insert(names, name or cppfile)
        end
        local name, _, cppfile = compiler_support.get_provided_module(modules[cycle[1]])
        table.insert(names, name or cppfile)
        raise("circular modules dependency detected!\n%s", table.concat(names, "\n   -> import "))
    end

    local objectfiles_sorted = table.reverse(dag:topological_sort())
    local objectfiles_sorted_set = hashset.from(objectfiles_sorted)
    for _, objectfile in ipairs(objectfiles) do
        if not objectfiles_sorted_set:has(objectfile) then
            table.insert(objectfiles_sorted, objectfile)
            objectfiles_sorted_set:insert(objectfile)
        end
    end
    local culleds
    for _, objectfile in ipairs(objectfiles_sorted) do
        local name, provide, cppfile = compiler_support.get_provided_module(modules[objectfile])
        local fileconfig = target:fileconfig(cppfile)
        local public
        local external
        local can_cull = true
        if fileconfig then
            public = fileconfig.public
            external = fileconfig.external
            can_cull = fileconfig.cull == nil and true or fileconfig.cull
        end
        can_cull = can_cull and target:policy("build.c++.modules.culling")
        local insert = true
        if provide then
            insert = public or (not external or external.moduleonly)
            if insert and not public and can_cull then
                insert = false
                local edges = dag:adjacent_edges(objectfile)
                local public = fileconfig and fileconfig.public
                if edges then
                    for _, edge in ipairs(edges) do
                        if edge:to() ~= objectfile and objectfiles_sorted_set:has(edge:to()) then
                            insert = true
                            break
                        end
                    end
                end
            end
        end
        if insert then 
            table.insert(build_objectfiles, objectfile)
            table.insert(link_objectfiles, objectfile)
        elseif external and not external.from_moduleonly then
            table.insert(build_objectfiles, objectfile)
        else
            objectfiles_sorted_set:remove(objectfile)
            if name ~= "std" and name ~= "std.compat" then
                culleds = culleds or {}
                culleds[target:name()] = culleds[target:name()] or {}
                table.insert(culleds[target:name()], format("%s -> %s", name, cppfile))
            end
        end
    end

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

    return build_objectfiles, link_objectfiles
end

-- get source modulefile for external target deps
function get_targetdeps_modules(target)
    local sourcefiles
    for _, dep in ipairs(target:orderdeps()) do
        local sourcebatch = dep:sourcebatches()["c++.build.modules.builder"]
        if sourcebatch and sourcebatch.sourcefiles then
            for _, sourcefile in ipairs(sourcebatch.sourcefiles) do
                local fileconfig = dep:fileconfig(sourcefile)
                local public = (fileconfig and fileconfig.public and not fileconfig.external) or false
                if public then
                    sourcefiles = sourcefiles or {}
                    table.insert(sourcefiles, sourcefile)
                    target:fileconfig_add(sourcefile, {external = {moduleonly = dep:is_moduleonly()}})
                end
            end
        end
    end
    return sourcefiles
end

