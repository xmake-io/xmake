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
        -- flang doesn't support -m64/-m32, use --target instead (especially on Linux)
        local target
        if toolchain:is_arch("x86_64", "x64") then
            target = "x86_64"
        elseif toolchain:is_arch("i386", "x86", "i686") then
            target = "i686"
        elseif toolchain:is_arch("arm64", "aarch64") then
            target = "aarch64"
        elseif toolchain:is_arch("arm") then
            target = "armv7"
        end
        
        if target then
            -- add target suffix based on platform
            if toolchain:is_plat("linux") then
                target = target .. "-linux-gnu"
            elseif toolchain:is_plat("windows") then
                target = target .. "-windows-msvc"
            elseif toolchain:is_plat("mingw") then
                target = target .. "-w64-windows-gnu"
            end
            
            -- only add --target on platforms that need it (Linux, Windows)
            -- macOS flang may work without explicit target
            if toolchain:is_plat("linux", "windows", "mingw") then
                toolchain:add("fcflags",   "--target=" .. target)
                toolchain:add("fcshflags", "--target=" .. target)
                toolchain:add("fcldflags", "--target=" .. target)
            end
        end
    end)

