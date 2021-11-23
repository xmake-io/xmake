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
    after_load(function (target)
        -- we disable to build across targets in parallel, because the source files may depend on other target modules
        -- @see https://github.com/xmake-io/xmake/issues/1858
        local target_with_modules
        for _, dep in ipairs(target:orderdeps()) do
            local sourcebatches = dep:sourcebatches()
            if sourcebatches and sourcebatches["c++.build.modules"] then
                target_with_modules = true
                break
            end
        end
        if target_with_modules then
            -- @note this will cause cross-parallel builds to be disabled for all sub-dependent targets,
            -- even if some sub-targets do not contain C++ modules.
            --
            -- maybe we will have a more fine-grained configuration strategy to disable it in the future.
            target:set("policy", "build.across_targets_in_parallel", false)
            local _, toolname = target:tool("cxx")
            if toolname:find("clang", 1, true) then
                import("build_modules.clang").load_parent(target, opt)
            elseif toolname:find("gcc", 1, true) then
                import("build_modules.gcc").load_parent(target, opt)
            elseif toolname == "cl" then
                import("build_modules.msvc").load_parent(target, opt)
            else
                raise("compiler(%s): does not support c++ module!", toolname)
            end
        end
    end)
    before_build_files(function (target, batchjobs, sourcebatch, opt)
        local _, toolname = target:tool("cxx")
        if toolname:find("clang", 1, true) then
            import("build_modules.clang").build_with_batchjobs(target, batchjobs, sourcebatch, opt)
        elseif toolname:find("gcc", 1, true) then
            import("build_modules.gcc").build_with_batchjobs(target, batchjobs, sourcebatch, opt)
        elseif toolname == "cl" then
            import("build_modules.msvc").build_with_batchjobs(target, batchjobs, sourcebatch, opt)
        else
            raise("compiler(%s): does not support c++ module!", toolname)
        end
    end, {batch = true})

