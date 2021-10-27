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

toolchain("circle")

    set_homepage("https://www.circle-lang.org/")
    set_description("A new C++20 compiler. It's written from scratch and designed for easy extension.")

    set_kind("standalone")

    set_toolset("cc", "circle")
    set_toolset("cxx", "circle")
    set_toolset("ld", "circle")
    set_toolset("sh", "circle")
    set_toolset("ar", "ar")
    set_toolset("strip", "strip")

    on_check(function (toolchain)
        return import("lib.detect.find_tool")("circle")
    end)

    on_load(function (toolchain)
        local march
        if toolchain:is_arch("x86_64", "x64") then
            march = "-m64"
        elseif toolchain:is_arch("i386", "x86") then
            march = "-m32"
        end
        if march then
            toolchain:add("cxflags", march)
            toolchain:add("ldflags", march)
            toolchain:add("shflags", march)
        end
    end)
