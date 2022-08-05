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
        import("modules_support.common")

        -- we disable to build across targets in parallel, because the source files may depend on other target modules
        -- @see https://github.com/xmake-io/xmake/issues/1858
        if common.contains_modules(target) then
            -- @note this will cause cross-parallel builds to be disabled for all sub-dependent targets,
            -- even if some sub-targets do not contain C++ modules.
            --
            -- maybe we will have a more fine-grained configuration strategy to disable it in the future.
            target:set("policy", "build.across_targets_in_parallel", false)

            -- get modules support
            local modules_support = common.modules_support(target)

            -- load module support
            modules_support.load(target)

            -- mark this target with modules
            target:data_set("cxx.has_modules", true)
        end
    end)

-- build dependencies
rule("c++.build.modules.dependencies")
    before_buildcmd(function(target, batchcmds, opt)
        if not target:data("cxx.has_modules") then
            return
        end

        -- patch sourcebatch
        import("modules_support.common")
        local sourcebatch = target:sourcebatches()["c++.build.modules.builder"]
        common.patch_sourcebatch(target, sourcebatch, opt)

        -- generate dependencies
        local modules_support = common.modules_support(target)
        modules_support.generate_dependencies(target, sourcebatch, opt)

        -- load and parse module dependencies
        local moduleinfos = common.load_moduleinfos(target, sourcebatch, opt)
        local modules = common.parse_dependency_data(target, moduleinfos, opt)
        target:data_set("cxx.modules", modules)
    end)

-- build modules
rule("c++.build.modules.builder")
    set_sourcekinds("cxx")
    set_extensions(".mpp", ".mxx", ".cppm", ".ixx")

    before_buildcmd_files(function(target, batchcmds, sourcebatch, opt)
        if not target:data("cxx.has_modules") then
            sourcebatch.objectfiles = {}
            return
        end

        import("modules_support.common")
        import("modules_support.stl_headers")

        -- patch sourcebatch
        common.patch_sourcebatch(target, sourcebatch, opt)

        -- get headerunits info
        local headerunits, stl_headerunits = common.get_headerunits(target, sourcebatch)

        -- generate headerunits
        local headerunits_flags
        local modules_support = common.modules_support(target)
        -- build stl header units as other headerunits may need them
        if stl_headerunits then
            headerunits_flags = headerunits_flags or {}
            table.join2(headerunits_flags, modules_support.generate_stl_headerunits(target, batchcmds, stl_headerunits, opt))
        end
        if headerunits then
            headerunits_flags = headerunits_flags or {}
            table.join2(headerunits_flags, modules_support.generate_user_headerunits(target, batchcmds, headerunits, opt))
        end
        if headerunits_flags then
            target:add("cxxflags", headerunits_flags, {force = true, expand = false})
        end

        -- topological sort
        local modules = target:data("cxx.modules")
        local objectfiles = common.sort_modules_by_dependencies(sourcebatch.objectfiles, modules)
        modules_support.build_modules(target, batchcmds, objectfiles, modules, opt)
    end)

-- install modules
rule("c++.build.modules.install")
    set_extensions(".mpp", ".mxx", ".cppm", ".ixx")

    before_install(function (target)
        import("modules_support.common")

        -- we cannot use target:data("cxx.has_modules"),
        -- because on_config will be not called when installing targets
        if common.contains_modules(target) then
            local sourcebatch = target:sourcebatches()["c++.build.modules.install"]
            if sourcebatch then
                target:add("installfiles", sourcebatch.sourcefiles, {prefixdir = "include"})
            end
        end
    end)
