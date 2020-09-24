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
-- Copyright (C) 2015-2020, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        xmake.lua
--

-- define toolchain
toolchain("clang")

    -- set homepage
    set_homepage("https://clang.llvm.org/")
    set_description("A C language family frontend for LLVM")

    -- mark as standalone toolchain
    set_kind("standalone")

    -- set toolset
    set_toolset("cc", "clang")
    set_toolset("cxx", "clang", "clang++")
    set_toolset("ld", "clang++", "clang")
    set_toolset("sh", "clang++", "clang")
    set_toolset("ar", "ar")
    set_toolset("ex", "ar")
    set_toolset("strip", "strip")
    set_toolset("mm", "clang")
    set_toolset("mxx", "clang", "clang++")
    set_toolset("as", "clang")

    -- check toolchain
    on_check(function (toolchain)
        return import("lib.detect.find_tool")("clang")
    end)

    -- on load
    on_load(function (toolchain)

        -- add march flags
        local march
        if toolchain:is_arch("x86_64", "x64") then
            march = "-m64"
        elseif toolchain:is_arch("i386", "x86") then
            march = "-m32"
        end
        if march then
            toolchain:add("cxflags", march)
            toolchain:add("mxflags", march)
            toolchain:add("asflags", march)
            toolchain:add("ldflags", march)
            toolchain:add("shflags", march)
        end

        -- add includedirs and linkdirs
        if not toolchain:is_plat("windows") and os.isdir("/usr") then
            for _, includedir in ipairs({"/usr/local/include", "/usr/include"}) do
                if os.isdir(includedir) then
                    toolchain:add("includedirs", includedir)
                end
            end
            for _, linkdir in ipairs({"/usr/local/lib", "/usr/lib"}) do
                if os.isdir(linkdir) then
                    toolchain:add("linkdirs", linkdir)
                end
            end
        end
    end)
