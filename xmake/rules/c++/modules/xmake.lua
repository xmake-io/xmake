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
-- @file        xmake.lua
--

-- define rule: c++.build.modules
rule("c++.build.modules")

    -- @note common.contains_modules() need it
    set_extensions(".cppm", ".ccm", ".cxxm", ".c++m", ".mpp", ".mxx", ".ixx")

    add_deps("c++.build.modules.builder")
    add_deps("c++.build.modules.install")

    on_config(function (target)
        import("modules_support.compiler_support")

        -- we disable to build across targets in parallel, because the source files may depend on other target modules
        -- @see https://github.com/xmake-io/xmake/issues/1858
        if compiler_support.contains_modules(target) then
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

            -- load compiler support
            compiler_support.load(target)

            -- mark this target with modules
            target:data_set("cxx.has_modules", true)

            -- moduleonly modules are implicitly public
            if target:is_moduleonly() then
                local sourcebatch = target:sourcebatches()["c++.build.modules.builder"]
                if sourcebatch then
                    for _, sourcefile in ipairs(sourcebatch.sourcefiles) do
                        target:fileconfig_add(sourcefile, {public = true})
                    end
                end
            end
        end
    end)

-- build modules
rule("c++.build.modules.builder")
    set_sourcekinds("cxx")
    set_extensions(".mpp", ".mxx", ".cppm", ".ixx")

    -- parallel build support to accelerate `xmake build` to build modules
    before_build_files(function(target, batchjobs, sourcebatch, opt)
        if target:data("cxx.has_modules") then
            import("modules_support.compiler_support")
            import("modules_support.dependency_scanner")
            import("modules_support.builder")

            -- add target deps modules
            if target:orderdeps() then
                local deps_sourcefiles = dependency_scanner.get_targetdeps_modules(target)
                if deps_sourcefiles then
                    table.join2(sourcebatch.sourcefiles, deps_sourcefiles)
                end
            end

            -- append std module
            local std_modules = compiler_support.get_stdmodules(target)
            if std_modules then
                table.join2(sourcebatch.sourcefiles, std_modules)
            end

            -- extract packages modules dependencies
            local package_modules_data = dependency_scanner.get_all_packages_modules(target, opt)
            if package_modules_data then
                -- append to sourcebatch
                for _, package_module_data in table.orderpairs(package_modules_data) do
                    table.insert(sourcebatch.sourcefiles, package_module_data.file)
                    target:fileconfig_set(package_module_data.file, {external = package_module_data.external, defines = package_module_data.metadata.defines})
                end
            end

            opt = opt or {}
            opt.batchjobs = true

            compiler_support.patch_sourcebatch(target, sourcebatch, opt)
            local modules = dependency_scanner.get_module_dependencies(target, sourcebatch, opt)

            if not target:is_moduleonly() then
                -- avoid building non referenced modules
                local build_objectfiles, link_objectfiles = dependency_scanner.sort_modules_by_dependencies(target, sourcebatch.objectfiles, modules)
                sourcebatch.objectfiles = build_objectfiles

                -- build modules
                builder.build_modules_for_batchjobs(target, batchjobs, sourcebatch, modules, opt)

                -- build headerunits and we need to do it before building modules
                builder.build_headerunits_for_batchjobs(target, batchjobs, sourcebatch, modules, opt)

                sourcebatch.objectfiles = link_objectfiles
            else
                sourcebatch.objectfiles = {}
            end

            compiler_support.localcache():set2(target:name(), "c++.modules", modules)
            compiler_support.localcache():save()
        else
            -- avoid duplicate linking of object files of non-module programs
            sourcebatch.objectfiles = {}
        end
    end, {batch = true})

    -- serial compilation only, usually used to support project generator
    before_buildcmd_files(function(target, batchcmds, sourcebatch, opt)
        if target:data("cxx.has_modules") then
            import("modules_support.compiler_support")
            import("modules_support.dependency_scanner")
            import("modules_support.builder")

            -- add target deps modules
            if target:orderdeps() then
                local deps_sourcefiles = dependency_scanner.get_targetdeps_modules(target)
                if deps_sourcefiles then
                    table.join2(sourcebatch.sourcefiles, deps_sourcefiles)
                end
            end

            -- append std module
            local std_modules = compiler_support.get_stdmodules(target)
            if std_modules then
                table.join2(sourcebatch.sourcefiles, std_modules)
            end

            -- extract packages modules dependencies
            local package_modules_data = dependency_scanner.get_all_packages_modules(target, opt)
            if package_modules_data then
                -- append to sourcebatch
                for _, package_module_data in table.orderpairs(package_modules_data) do
                    table.insert(sourcebatch.sourcefiles, package_module_data.file)
                    target:fileconfig_set(package_module_data.file, {external = package_module_data.external, defines = package_module_data.metadata.defines})
                end
            end

            opt = opt or {}
            opt.batchjobs = false

            compiler_support.patch_sourcebatch(target, sourcebatch, opt)
            local modules = dependency_scanner.get_module_dependencies(target, sourcebatch, opt)

            if not target:is_moduleonly() then
                -- avoid building non referenced modules
                local build_objectfiles, link_objectfiles = dependency_scanner.sort_modules_by_dependencies(target, sourcebatch.objectfiles, modules)
                sourcebatch.objectfiles = build_objectfiles

                -- build headerunits
                builder.build_headerunits_for_batchcmds(target, batchcmds, sourcebatch, modules, opt)

                -- build modules
                builder.build_modules_for_batchcmds(target, batchcmds, sourcebatch, modules, opt)

                sourcebatch.objectfiles = link_objectfiles
            else
                -- avoid duplicate linking of object files of non-module programs
                sourcebatch.objectfiles = {}
            end

            compiler_support.localcache():set2(target:name(), "c++.modules", modules)
            compiler_support.localcache():save()
        else
            sourcebatch.sourcefiles = {}
            sourcebatch.objectfiles = {}
            sourcebatch.dependfiles = {}
        end
    end)

    after_clean(function (target)
        import("core.base.option")
        import("modules_support.compiler_support")
        import("private.action.clean.remove_files")

        -- we cannot use target:data("cxx.has_modules"),
        -- because on_config will be not called when cleaning targets
        if compiler_support.contains_modules(target) then
            remove_files(compiler_support.modules_cachedir(target))
            if option.get("all") then
                remove_files(compiler_support.stlmodules_cachedir(target))
                compiler_support.localcache():clear()
                compiler_support.localcache():save()
            end
        end
    end)

-- install modules
rule("c++.build.modules.install")
    set_extensions(".mpp", ".mxx", ".cppm", ".ixx")

    before_install(function (target)
        import("modules_support.compiler_support")
        import("modules_support.builder")

        -- we cannot use target:data("cxx.has_modules"),
        -- because on_config will be not called when installing targets
        if compiler_support.contains_modules(target) then
            local modules = compiler_support.localcache():get2(target:name(), "c++.modules")
            builder.generate_metadata(target, modules)

            compiler_support.add_installfiles_for_modules(target)
        end
    end)

    before_uninstall(function (target)
        import("modules_support.compiler_support")
        if compiler_support.contains_modules(target) then
            compiler_support.add_installfiles_for_modules(target)
        end
    end)
