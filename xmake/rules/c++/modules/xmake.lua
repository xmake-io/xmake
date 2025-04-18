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
        import("compiler_support")

        -- we disable to build across targets in parallel, because the source files may depend on other target modules
        -- @see https://github.com/xmake-io/xmake/issues/1858
        if compiler_support.contains_modules(target) then
            -- @note this will cause cross-parallel builds to be disabled for all sub-dependent targets,
            -- even if some sub-targets do not contain C++ modules.
            --
            -- maybe we will have a more fine-grained configuration strategy to disable it in the future.
            target:set("policy", "build.fence", true)

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

    -- generate module dependencies
    on_prepare_files(function (target, jobgraph, sourcebatch, opt)
        if target:data("cxx.has_modules") then
            import("builder")
            import("dependency_scanner")

            -- patch sourcebatch
            builder.patch_sourcebatch(target, sourcebatch)

            -- generate module dependencies
            dependency_scanner.generate_module_dependencies(target, jobgraph, sourcebatch, opt)
        end
    end, {jobgraph = true})

    -- parallel build support to accelerate `xmake build` to build modules
    before_build_files(function(target, jobgraph, sourcebatch, opt)
        if target:data("cxx.has_modules") then
            import("compiler_support")
            import("dependency_scanner")
            import("builder")

            -- get module dependencies
            local modules = dependency_scanner.get_module_dependencies(target, sourcebatch)
            if not target:is_moduleonly() then
                -- avoid building non referenced modules
                local build_objectfiles, link_objectfiles = dependency_scanner.sort_modules_by_dependencies(target, sourcebatch.objectfiles, modules)
                sourcebatch.objectfiles = build_objectfiles

                -- build modules and headerunits
                builder.build_modules_and_headerunits(target, jobgraph, sourcebatch, modules, opt)
                sourcebatch.objectfiles = link_objectfiles
            else
                sourcebatch.objectfiles = {}
            end

            compiler_support.localcache():set2(target:fullname(), "c++.modules", modules)
            compiler_support.localcache():save()
        else
            -- avoid duplicate linking of object files of non-module programs
            sourcebatch.objectfiles = {}
        end
    end, {jobgraph = true, batch = true})

    -- serial compilation only, usually used to support project generator
    before_buildcmd_files(function(target, batchcmds, sourcebatch, opt)
        if target:data("cxx.has_modules") then
            import("compiler_support")
            import("dependency_scanner")
            import("builder")

            -- get module dependencies
            local modules = dependency_scanner.get_module_dependencies(target, sourcebatch)
            if not target:is_moduleonly() then
                -- avoid building non referenced modules
                local build_objectfiles, link_objectfiles = dependency_scanner.sort_modules_by_dependencies(target, sourcebatch.objectfiles, modules)
                sourcebatch.objectfiles = build_objectfiles

                -- build headerunits and modules
                builder.build_modules_and_headerunits(target, batchcmds, sourcebatch, modules, opt)
                sourcebatch.objectfiles = link_objectfiles
            else
                -- avoid duplicate linking of object files of non-module programs
                sourcebatch.objectfiles = {}
            end

            compiler_support.localcache():set2(target:fullname(), "c++.modules", modules)
            compiler_support.localcache():save()
        else
            sourcebatch.sourcefiles = {}
            sourcebatch.objectfiles = {}
            sourcebatch.dependfiles = {}
        end
    end)

    after_clean(function (target)
        import("core.base.option")
        import("compiler_support")
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
        import("compiler_support")
        import("builder")

        -- we cannot use target:data("cxx.has_modules"),
        -- because on_config will be not called when installing targets
        if compiler_support.contains_modules(target) then
            local modules = compiler_support.localcache():get2(target:fullname(), "c++.modules")
            builder.generate_metadata(target, modules)

            compiler_support.add_installfiles_for_modules(target)
        end
    end)

    before_uninstall(function (target)
        import("compiler_support")
        if compiler_support.contains_modules(target) then
            compiler_support.add_installfiles_for_modules(target)
        end
    end)
