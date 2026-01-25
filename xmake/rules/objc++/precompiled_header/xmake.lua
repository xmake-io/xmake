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

rule("objc.build.pcheader")
    on_config(function (target, opt)
        import("private.action.build.pcheader")
        if not pcheader.config(target, "m", opt) then
            target:rule_enable("objc.build.pcheader", false)
        end
    end)

    before_build(function (target, jobgraph, opt)
        if not os.getenv("XMAKE_IN_COMPILE_COMMANDS_PROJECT_GENERATOR") then
            import("private.action.build.pcheader").build(target, jobgraph, "m", opt)
        end
    end, {jobgraph = true})

rule("objc++.build.pcheader")
    add_orders("objc++.build.pcheader", "c++.build.modules.builder")
    on_config(function (target, opt)
        import("private.action.build.pcheader")
        if not pcheader.config(target, "mxx", opt) then
            target:rule_enable("objc++.build.pcheader", false)
        end
    end)

    -- Since Objective-C typically does not have C++ modules,
    -- we can always enable parallel compilation across targets
    -- without blocking the compilation of other cpp files,
    -- we perform this as much as possible during the before_build stage.
    before_build(function (target, jobgraph, opt)
        import("private.action.build.pcheader").build(target, jobgraph, "mxx", opt)
    end, {jobgraph = true})

