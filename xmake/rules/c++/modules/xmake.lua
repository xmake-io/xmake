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

            -- disable ccache for this target
            --
            -- Caching can affect incremental compilation, for example
            -- by interfering with the results of depfile generation for msvc.
            --
            -- @see https://github.com/xmake-io/xmake/issues/3000
            target:set("policy", "build.ccache", false)

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

    -- parallel build support to accelerate `xmake build` to build modules
    before_build_files(function(target, batchjobs, sourcebatch, opt)
        if target:data("cxx.has_modules") then
            import("modules_support.common")
            common.patch_sourcebatch(target, sourcebatch, opt)
            local modules = common.get_module_dependencies(target, sourcebatch, opt)

            -- build modules
            common.build_modules_for_batchjobs(target, batchjobs, sourcebatch, modules, opt)

            -- generate headerunits and we need do it before building modules
            local user_headerunits, stl_headerunits = common.get_headerunits(target, sourcebatch, modules)
            if user_headerunits or stl_headerunits then
                -- we need new group(headerunits)
                -- e.g. group(build_modules) -> group(headerunits)
                opt.rootjob = batchjobs:group_leave() or opt.rootjob
                batchjobs:group_enter(target:name() .. "/generate_headerunits", {rootjob = opt.rootjob})
                local modules_support = common.modules_support(target)
                if stl_headerunits then
                    -- build stl header units as other headerunits may need them
                    -- TODO maybe we need new group(build_modules) -> group(user_headerunits) -> group(stl_headerunits)
                    modules_support.generate_stl_headerunits_for_batchjobs(target, batchjobs, stl_headerunits, opt)
                end
                if user_headerunits then
                    modules_support.generate_user_headerunits_for_batchjobs(target, batchjobs, user_headerunits, opt)
                end
            end
        else
            -- avoid duplicate linking of object files of non-module programs
            sourcebatch.objectfiles = {}
        end
    end, {batch = true})

    -- serial compilation only, usually used to support project generator
    before_buildcmd_files(function(target, batchcmds, sourcebatch, opt)
        if target:data("cxx.has_modules") then
            import("modules_support.common")

            -- patch sourcebatch
            common.patch_sourcebatch(target, sourcebatch, opt)

            -- generate headerunits
            local modules = common.get_module_dependencies(target, sourcebatch, opt)
            common.generate_headerunits_for_batchcmds(target, batchcmds, sourcebatch, modules, opt)

            -- build modules
            common.build_modules_for_batchcmds(target, batchcmds, sourcebatch, modules, opt)
        else
            -- avoid duplicate linking of object files of non-module programs
            sourcebatch.objectfiles = {}
        end
    end)

    before_link(function (target)
        import("modules_support.common")
        if target:data("cxx.has_modules") then
            common.append_dependency_objectfiles(target)
        end
    end)

    after_clean(function (target)
        import("core.base.option")
        import("modules_support.common")
        import("private.action.clean.remove_files")

        -- we cannot use target:data("cxx.has_modules"),
        -- because on_config will be not called when cleaning targets
        if common.contains_modules(target) then
            remove_files(common.modules_cachedir(target))
            if option.get("all") then
                remove_files(common.stlmodules_cachedir(target))
                common.localcache():clear()
                common.localcache():save()
            end
        end
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
                for _, sourcefile in sourcebatch.sourcefiles do
                    local prefixdir = "modules"
                    local fileconfig = target:fileconfig(sourcefile)
                    if fileconfig and fileconfig.prefixdir then
                        prefixdir = fileconfig.prefixdir
                    end
                    local install = (fileconfig and not fileconfig.install) and false or true
                    if install then
                        target:add("installfiles", sourcefile, {prefixdir = prefixdir})
                    end
                end
            end
        end
    end)
