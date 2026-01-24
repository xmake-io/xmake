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

rule("c.build.pcheader")
    on_config(function (target, opt)
        import("private.action.build.pcheader").config(target, "c", opt)
    end)

    before_build(function (target, jobgraph, opt)
        if not os.getenv("XMAKE_IN_COMPILE_COMMANDS_PROJECT_GENERATOR") then
            import("private.action.build.pcheader").build(target, jobgraph, "c", opt)
        end
    end, {jobgraph = true})

rule("c++.build.pcheader")
    on_config(function (target, opt)
        import("private.action.build.pcheader").config(target, "cxx", opt)
    end)

    -- If the current target has a C++ modules file,
    -- we can only compile it earlier in the before_prepare stage,
    -- because the C++ modules will perform a complete dependency scan of
    -- the C++ files in on_prepare and then build the dependency graph.
    -- At this time, the pch header file must have already been generated.
    before_prepare(function (target, jobgraph, opt)
        local has_modules = target:data("cxx.has_modules")
        if has_modules and not os.getenv("XMAKE_IN_COMPILE_COMMANDS_PROJECT_GENERATOR") then
            import("private.action.build.pcheader").build(target, jobgraph, "cxx", opt)
        end
    end, {jobgraph = true})

    -- To enable parallel compilation across targets
    -- without blocking the compilation of other cpp files,
    -- we perform this as much as possible during the before_build stage.
    --
    -- @see: https://github.com/xmake-io/xmake/issues/4167
    before_build(function (target, jobgraph, opt)
        local has_modules = target:data("cxx.has_modules")
        if not has_modules then
            import("private.action.build.pcheader").build(target, jobgraph, "cxx", opt)
        end
    end, {jobgraph = true})

