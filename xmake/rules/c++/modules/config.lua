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
-- @file        config.lua
--

import("core.project.project")
import("core.base.semver")
import("support")

function main(target)

    if support.contains_modules(target) then
        -- when jobgraph is policy is set to false, we disable to build across targets in parallel, because the source files may depend on other target modules
        -- @see https://github.com/xmake-io/xmake/issues/1858
        -- @note this will cause cross-parallel builds to be disabled for all sub-dependent targets,
        -- even if some sub-targets do not contain C++ modules.
        if not target:policy("build.jobgraph") or target:data("in_project_generator") then
            target:set("policy", "build.fence", true)
        end

        assert(not target:rule("c++.unity_build"), "C++ unity build is not compatible with C++ modules")

        -- disable ccache for this target
        --
        -- Caching can affect incremental compilation, for example
        -- by interfering with the results of depfile generation for msvc.
        --
        -- @see https://github.com/xmake-io/xmake/issues/3000
        target:set("policy", "build.ccache", false)

        -- load compiler support
        support.load(target)

        -- mark this target with modules
        target:data_set("cxx.has_modules", true)

        -- warn about deprecated policies
        if target:policy("build.c++.gcc.modules.cxx11abi") then
            wprint("build.c++.gcc.modules.cxx11abi is deprecated, please use build.c++.modules.gcc.cxx11abi")
        end
        if target:policy("build.c++.clang.fallbackscanner") then
            wprint("build.c++.clang.fallbackscanner is deprecated, please use build.c++.modules.clang.fallbackscanner")
        end
        if target:policy("build.c++.gcc.fallbackscanner") then
            wprint("build.c++.gcc.fallbackscanner is deprecated, please use build.c++.modules.gcc.fallbackscanner")
        end
        if target:policy("build.c++.msvc.fallbackscanner") then
            wprint("build.c++.msvc.fallbackscanner is deprecated, please use build.c++.modules.msvc.fallbackscanner")
        end
        if target:policy("build.c++.modules.tryreuse") then
            wprint("build.c++.modules.tryreuse is deprecated, please use build.c++.modules.reuse")
        end
        if target:policy("build.c++.modules.tryreuse.discriminate_on_defines") then
            wprint("build.c++.modules.tryreuse.discriminate_on_defines is deprecated, please use build.c++.modules.reuse.strict")
        end

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
end

function insert_stdmodules(target)

    if target:data("cxx.has_modules") then
        -- add std modules to sourcebatch
        local stdmodules = support.get_stdmodules(target)
        for _, sourcefile in ipairs(stdmodules) do
            table.insert(target:sourcebatches()["c++.build.modules.scanner"].sourcefiles, sourcefile)
            table.insert(target:sourcebatches()["c++.build.modules.builder"].sourcefiles, sourcefile)
        end
    end
end
