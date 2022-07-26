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
    add_deps("c++.build.modules.builder")

    on_config(function (target)
        local target_with_modules = (target:modulefiles() and #target:modulefiles() > 0) and true or false

        for _, dep in ipairs(target:orderdeps()) do
            local modulefiles = dep:get("modulefiles")
            if modulefiles and #modulefiles > 0 then
                target_with_modules = true
                break
            end
        end

        if target_with_modules then
            target:set("policy", "build.across_targets_in_parallel", false)

            -- import build_modules
            local build_modules
            if target:has_tool("cxx", "clang", "clangxx") then
                build_modules = import("build_modules.clang")
            elseif target:has_tool("cxx", "gcc", "gxx") then
                build_modules = import("build_modules.gcc")
            elseif target:has_tool("cxx", "cl") then
                build_modules = import("build_modules.msvc")
            else
                local _, toolname = target:tool("cxx")
                raise("compiler(%s): does not support c++ module!", toolname)
            end

            -- check C++20 module support
            build_modules.check_module_support(target)

            -- load parent
            build_modules.load_parent(target, opt)

            for _, modulefile in ipairs(target:modulefiles()) do
                target:add("files", modulefile)
            end

            target:set("cxx.has_modules", true)
        end
    end)

    before_build(function(target, opt) 
        if not target:get("cxx.has_modules") then
            return
        end

        local build_modules
        if target:has_tool("cxx", "clang", "clangxx") then
            build_modules = import("build_modules.clang")
        elseif target:has_tool("cxx", "gcc", "gxx") then
            build_modules = import("build_modules.gcc")
        elseif target:has_tool("cxx", "cl") then
            build_modules = import("build_modules.msvc")
        else
            local _, toolname = target:tool("cxx")
            raise("compiler(%s): does not support c++ module!", toolname)
        end

        -- build dependency data
        local common = import("build_modules.common")

        local moduleinfos = {}
        for _, sourcebatch in pairs(target:sourcebatches()) do
            if sourcebatch.rulename == "c++.build.modules.builder" then
                build_modules.patch_sourcebatch(target, sourcebatch, opt)
            end

            build_modules.generate_dependencies(target, sourcebatch, opt)
            local infos = common.load(target, sourcebatch, opt)

            table.join2(moduleinfos, infos or {})
        end

        local modules = common.parse_dependency_data(target, moduleinfos, opt)

        target:data_set("cxx.modules", modules)
    end)


rule("c++.build.modules.builder")
    set_extensions(".mpp", ".mxx", ".cppm", ".ixx")
    add_deps("c++.build.modules.builder.headerunits")

    before_buildcmd_files(function(target, batchcmds, sourcebatch, opt)
        if not target:get("cxx.has_modules") then
            return
        end

        local build_modules
        if target:has_tool("cxx", "clang", "clangxx") then
            build_modules = import("build_modules.clang")
        elseif target:has_tool("cxx", "gcc", "gxx") then
            build_modules = import("build_modules.gcc")
        elseif target:has_tool("cxx", "cl") then
            build_modules = import("build_modules.msvc")
        else
            local _, toolname = target:tool("cxx")
            raise("compiler(%s): does not support c++ module!", toolname)
        end

        local common = import("build_modules.common")

        local modules = target:data("cxx.modules")

        local nodes = sourcebatch.objectfiles

        -- topological sort
        local objectfiles = common.sort_modules_by_dependencies(sourcebatch.objectfiles, modules)

        build_modules.build_modules(target, batchcmds, objectfiles, modules, opt)
    end, {batch = true})

rule("c++.build.modules.builder.headerunits")
    set_sourcekinds("cxx")
    set_extensions(".mpp", ".mxx", ".cppm", ".ixx")

    before_buildcmd_files(function(target, batchcmds, sourcebatch, opt)
        if not target:get("cxx.has_modules") then
            return
        end

        local build_modules
        if target:has_tool("cxx", "clang", "clangxx") then
            build_modules = import("build_modules.clang")
        elseif target:has_tool("cxx", "gcc", "gxx") then
            build_modules = import("build_modules.gcc")
        elseif target:has_tool("cxx", "cl") then
            build_modules = import("build_modules.msvc")
        else
            local _, toolname = target:tool("cxx")
            raise("compiler(%s): does not support c++ module!", toolname)
        end

        sourcebatch.objectfiles = {}
        sourcebatch.dependfiles = {}
        build_modules.patch_sourcebatch(target, sourcebatch, opt)

        local common = import("build_modules.common")

        local modules = target:data("cxx.modules")

        local headerunits
        for _, objectfile in ipairs(sourcebatch.objectfiles) do
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

        if headerunits then
            build_modules.generate_headerunits(target, batchcmds, headerunits, opt)
        end
    end, {batch = true})