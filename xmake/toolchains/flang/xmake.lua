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

-- define toolchain
toolchain("flang")

    -- set homepage
    set_homepage("https://flang.llvm.org/")
    set_description("LLVM Fortran Compiler")

    -- mark as standalone toolchain
    set_kind("standalone")

    -- set toolset
    set_toolset("fc",   "$(env FC)", "flang")
    set_toolset("fcld", "$(env FC)", "flang")
    set_toolset("fcsh", "$(env FC)", "flang")
    set_toolset("ar",   "llvm-ar", "ar")

    -- on check
    on_check(function (toolchain)
        return import("lib.detect.find_tool")("flang", {program = "flang"})
    end)

    -- on load
    on_load(function (toolchain)
        local march
        if toolchain:is_arch("x86_64", "x64", "arm64") then
            march = "-m64"
        elseif toolchain:is_arch("i386", "x86", "i686") then
            march = "-m32"
        end
        if march then
            toolchain:add("fcflags",   march)
            toolchain:add("fcshflags", march)
            toolchain:add("fcldflags", march)
        end
    end)

