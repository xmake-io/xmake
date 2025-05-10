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

rule("c.build.pcheader")
    on_config(function (target, opt)
        import("private.action.build.pcheader").config(target, "c", opt)
    end)
    before_prepare(function (target, jobgraph, opt)
        import("private.action.build.pcheader").build(target, jobgraph, "c", opt)
    end, {jobgraph = true})

rule("c++.build.pcheader")
    add_orders("c++.build.modules.scanner", "c++.build.pcheader", "c++.build.modules.builder")
    on_config(function (target, opt)
        import("private.action.build.pcheader").config(target, "cxx", opt)
    end)
    before_prepare(function (target, jobgraph, opt)
        import("private.action.build.pcheader").build(target, jobgraph, "cxx", opt)
    end, {jobgraph = true})

