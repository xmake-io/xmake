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

-- build modules
rule("c++.build.modules.builder")
    set_sourcekinds("cxx")
    set_extensions(".mpp", ".mxx", ".cppm", ".ixx")

    -- TODO parallel build support to accelerate `xmake build` to build modules
    --[[
    before_build_files(function(target, batchjobs, sourcebatch, opt)
        if not target:data("cxx.has_modules") then
            sourcebatch.objectfiles = {}
            return
        end

        -- patch sourcebatch
        import("modules_support.common")
        common.patch_sourcebatch(target, sourcebatch, opt)

        -- generate dependencies
        local modules = common.generate_dependencies(target, sourcebatch, opt)

        -- generate headerunits
        local headerunits_flags = common.generate_headerunits_for_batchjobs(target, batchjobs, sourcebatch, modules, opt)
        if headerunits_flags then
            target:add("cxxflags", headerunits_flags, {force = true, expand = false})
        end

        -- build modules
        common.build_modules_for_batchjobs(target, batchjobs, sourcebatch, modules, opt)
    end, {batch = true})]]

    -- serial compilation only, usually used to support project generator
    before_buildcmd_files(function(target, batchcmds, sourcebatch, opt)
        if not target:data("cxx.has_modules") then
            sourcebatch.objectfiles = {}
            return
        end

        -- patch sourcebatch
        import("modules_support.common")
        common.patch_sourcebatch(target, sourcebatch, opt)

        -- generate dependencies
        local modules = common.generate_dependencies(target, sourcebatch, opt)

        -- generate headerunits
        local headerunits_flags = common.generate_headerunits_for_batchcmds(target, batchcmds, sourcebatch, modules, opt)
        if headerunits_flags then
            target:add("cxxflags", headerunits_flags, {force = true, expand = false})
        end

        -- build modules
        common.build_modules_for_batchcmds(target, batchcmds, sourcebatch, modules, opt)
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
