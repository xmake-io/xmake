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
-- Copyright (C) 2015-present, Xmake Open Source Community.
--
-- @author      ruki
-- @file        xmake.lua
--

-- define rule: swift.build
rule("swift.build")
    set_sourcekinds("sc")
    on_build_files("private.action.build.object", {jobgraph = true, batch = true})
    on_config(function (target)
        if target:is_library() then
            target:add("scflags", "-parse-as-library")
        end

        -- we use swift-frontend to support multiple modules
        -- @see https://github.com/xmake-io/xmake/issues/3916
        if target:has_tool("sc", "swift_frontend") then
            target:add("scflags", "-module-name", target:name(), {force = true})
            local sourcebatch = target:sourcebatches()["swift.build"]
            if sourcebatch then
                for _, sourcefile in ipairs(sourcebatch.sourcefiles) do
                    target:add("scflags", sourcefile, {force = true})
                end
            end
        end
    end)

-- define rule: swift
rule("swift")

    -- add build rules
    add_deps("swift.build")

    -- set compiler runtime, e.g. vs runtime
    add_deps("utils.compiler.runtime")

    -- inherit links and linkdirs of all dependent targets by default
    add_deps("utils.inherit.links")

    -- support `add_files("src/*.o")` to merge object files to target
    add_deps("utils.merge.object")

    -- add linker rules
    add_deps("linker")
