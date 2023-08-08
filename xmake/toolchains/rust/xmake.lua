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

toolchain("rust")

    set_homepage("https://www.rust-lang.org/")
    set_description("Rust Programming Language Compiler")

--    set_kind("standalone")

    set_toolset("rc",   "$(env RC)", "rustc")
    set_toolset("rcld", "$(env RC)", "rustc")
    set_toolset("rcsh", "$(env RC)", "rustc")
    set_toolset("rcar", "$(env RC)", "rustc")

    on_check(function (toolchain)
        import("lib.detect.find_tool")
        return find_tool("rustc")
    end)

    on_load(function (toolchain)
        -- for cross-compilation, e.g. xmake f -p cross --cross=aarch64-unknown-none
        local cross = toolchain:cross()
        if toolchain:is_cross() and cross then
            toolchain:add("rcshflags", "--target=" .. cross)
            toolchain:add("rcldflags", "--target=" .. cross)
        else
            toolchain:set("rcshflags", "")
            toolchain:set("rcldflags", "")
        end
    end)
