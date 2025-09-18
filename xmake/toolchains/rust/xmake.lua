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

toolchain("rust")
    set_homepage("https://www.rust-lang.org/")
    set_description("Rust Programming Language Compiler")

    set_toolset("rc",   "$(env RC)", "rustc")
    set_toolset("rcld", "$(env RC)", "rustc")
    set_toolset("rcsh", "$(env RC)", "rustc")
    set_toolset("rcar", "$(env RC)", "rustc")

    on_load(function (toolchain)
        import("core.tools.rustc.target_triple")

        local opt = {}
        if toolchain:config("appledev") == "simulator" then
            opt.apple_sim = true
        end

        local target = target_triple(toolchain:plat(), toolchain:arch(), opt)
        if target then
            toolchain:add("rcflags", "--target=" .. target)
        else
            toolchain:set("rcshflags", "")
            toolchain:set("rcldflags", "")
        end
    end)
