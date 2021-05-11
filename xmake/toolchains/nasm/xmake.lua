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

-- define toolchain
toolchain("nasm")

    -- set homepage
    set_homepage("https://www.nasm.us/")
    set_description("NASM Assembler")

    -- set toolset
    set_toolset("as", "nasm")

    -- on load
    on_load(function (toolchain)
        local asflags = "" -- maybe 16bits if no flags
        if toolchain:is_plat("macosx") then
            if toolchain:is_arch("x86_64") then
                asflags = "-f macho64"
            elseif toolchain:is_arch("i386") then
                asflags = "-f macho32"
            end
        elseif toolchain:is_plat("linux", "android", "bsd") then
            if toolchain:is_arch("x86_64") then
                asflags = "-f elf64"
            elseif toolchain:is_arch("i386") then
                asflags = "-f elf32"
            end
        elseif toolchain:is_plat("windows", "mingw", "msys", "cygwin") then
            if toolchain:is_arch("x64", "x86_64") then
                asflags = "-f win64"
            elseif toolchain:is_arch("x86", "i386") then
                asflags = "-f win32"
            end
        end
        toolchain:add("nasm.asflags", asflags)
    end)
