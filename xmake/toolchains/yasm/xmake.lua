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
toolchain("yasm")

    -- set homepage
    set_homepage("https://yasm.tortall.net/")
    set_description("The Yasm Modular Assembler")

    -- set toolset
    set_toolset("as", "yasm")

    -- on load
    on_load(function (toolchain)
        if toolchain:is_plat("macosx") then
            toolchain:add("yasm.asflags", "-f", toolchain:is_arch("x86_64") and "macho64" or "macho32")
        elseif toolchain:is_plat("linux", "bsd") then
            toolchain:add("yasm.asflags", "-f", toolchain:is_arch("x86_64") and "elf64" or "elf32")
        elseif toolchain:is_plat("windows", "mingw", "msys", "cygwin") then
            toolchain:add("yasm.asflags", "-f", toolchain:is_arch("x86_64", "x64") and "win64" or "win32")
        end
    end)
