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
    before_build(function (target, opt)
        local sourcebatches = target:sourcebatches()
        if sourcebatches then
            local sourcebatch = sourcebatches["c++.build.modules"]
            if sourcebatch then
                import("moduledeps").generate(target, sourcebatch, opt)
            end
        end
    end)
    before_build_files(function (target, batchjobs, sourcebatch, opt)
        -- we disable to build across targets in parallel, because the source files may depend on other target modules
        -- @note we cannot set it in on_load, because it will affect all c++ projects
        target:set("policy", "build.across_targets_in_parallel", false)

        -- build module files with batchjobs
        local _, toolname = target:tool("cxx")
        if toolname:find("clang", 1, true) then
            import("clang").build_with_batchjobs(target, batchjobs, sourcebatch, opt)
        elseif toolname:find("gcc", 1, true) then
            import("gcc").build_with_batchjobs(target, batchjobs, sourcebatch, opt)
        elseif toolname == "cl" then
            import("msvc").build_with_batchjobs(target, batchjobs, sourcebatch, opt)
        else
            raise("compiler(%s): does not support c++ module!", toolname)
        end
    end, {batch = true})

