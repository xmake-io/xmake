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
-- @file        xmake.lua
--

-- define rule: c++.build.modules
rule("c++.build.modules")
    set_extensions(".mpp", ".mxx", ".cppm", ".ixx")
    add_deps("c++.build.modules.dependencies")
    add_deps("c++.build.modules.builder")
    add_deps("c++.build.modules.install")

    on_config(function (target)
        -- we disable to build across targets in parallel, because the source files may depend on other target modules
        -- @see https://github.com/xmake-io/xmake/issues/1858

        function contains_modules(target)
            local target_with_modules
            for _, dep in ipairs(target:orderdeps()) do
                local sourcebatches = dep:sourcebatches()
                if sourcebatches and sourcebatches["c++.build.modules"] then
                    target_with_modules = true
                    break
                end
            end
            return target_with_modules
        end

        local target_with_modules = target:sourcebatches()["c++.build.modules"] and contains_modules(target) or false
        if target_with_modules then
            -- @note this will cause cross-parallel builds to be disabled for all sub-dependent targets,
            -- even if some sub-targets do not contain C++ modules.
            --
            -- maybe we will have a more fine-grained configuration strategy to disable it in the future.
            target:set("policy", "build.across_targets_in_parallel", false)

            local common = import("modules_support.common")
            local modules_support = common.modules_support(target)

            -- check C++20 module support
            modules_support.check_module_support(target)

            -- load parent
            modules_support.load_parent(target, opt)

            target:set("cxx.has_modules", true)
        end
    end)


rule("c++.build.modules.dependencies")
    before_build(function(target, opt) 
        if not target:get("cxx.has_modules") then
            return
        end

        local common = import("modules_support.common")
        local modules_support = common.modules_support(target)

        -- build dependency data
        local batch = target:sourcebatches()["c++.build.modules.builder"]
        common.patch_sourcebatch(target, batch, opt)

        modules_support.generate_dependencies(target, batch, opt)

        local moduleinfos = common.load(target, batch, opt)
        local modules = common.parse_dependency_data(target, moduleinfos, opt)

        target:data_set("cxx.modules", modules)
    end)

rule("c++.build.modules.builder")
    set_sourcekinds("cxx")
    set_extensions(".mpp", ".mxx", ".cppm", ".ixx")

    before_buildcmd_files(function(target, batchcmds, sourcebatch, opt)
        if not target:get("cxx.has_modules") then
            sourcebatch.objectfiles = {}
            return
        end

        local common = import("modules_support.common")
        local modules_support = common.modules_support(target)

        local batch = sourcebatch

        batch.objectfiles = {}
        batch.dependfiles = {}
        common.patch_sourcebatch(target, batch, opt)

        local modules = target:data("cxx.modules")

        local headerunits
        for _, objectfile in ipairs(batch.objectfiles) do
            for obj, m in pairs(modules) do
                if obj == objectfile then
                    for name, r in pairs(m.requires) do
                        if r.method ~= "by-name" then
                            headerunits = headerunits or {}

                            local type = r.method == "include-angle" and ":angle" or ":quote"
                            table.append(headerunits, { name = name, path = r.path, type = type, stl = common.is_stl_header(name) })
                        end
                    end
                    break
                end
            end
        end

        local headerunits_flags
        local private_headerunits_flags
        if headerunits then
            headerunits_flags, private_headerunits_flags = modules_support.generate_headerunits(target, batchcmds, headerunits, opt)
        end

        if headerunits_flags then
            target:add("cxxflags", headerunits_flags, {force = true, expand = false})
        end
        if private_headerunits_flags then
            target:add("cxxflags", private_headerunits_flags, {force = true, expand = false})
        end

        local modules = target:data("cxx.modules")

        -- topological sort
        local objectfiles = common.sort_modules_by_dependencies(batch.objectfiles, modules)

        modules_support.build_modules(target, batchcmds, objectfiles, modules, opt)
    end)

rule("c++.build.modules.install")
    set_extensions(".mpp", ".mxx", ".cppm", ".ixx")

    before_install(function (target)
        local sourcebatch = target:sourcebatches()["c++.build.modules.install"]

        if sourcebatch then 
            target:add("installfiles", sourcebatch.sourcefiles, {prefixdir = "include"})
        end
    end)