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
-- @file        config.lua
--

import("support")
    
function main(target)

    -- we disable to build across targets in parallel, because the source files may depend on other target modules
    -- @see https://github.com/xmake-io/xmake/issues/1858
    if support.contains_modules(target) then

        -- unity build can't work with modules
        assert(not target:rule("c++.unity_build"), "C++ unity build is not compatible with C++ modules")

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
        support.load(target)

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
end
