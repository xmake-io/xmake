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
toolchain("llvm")

    -- set homepage
    set_homepage("https://llvm.org/")
    set_description("A collection of modular and reusable compiler and toolchain technologies")

    -- mark as standalone toolchain
    set_kind("standalone")

    -- set toolset
    set_toolset("cc",     "clang")
    set_toolset("cxx",    "clang", "clang++")
    set_toolset("cpp",    "clang -E")
    set_toolset("as",     "clang")
    set_toolset("ld",     "clang++", "clang")
    set_toolset("sh",     "clang++", "clang")
    set_toolset("ar",     "llvm-ar")
    set_toolset("ex",     "llvm-ar")
    set_toolset("ranlib", "llvm-ranlib")
    set_toolset("strip",  "llvm-strip")

    -- check toolchain
    on_check("check")

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

        -- init linkdirs and includedirs
        local sdkdir = toolchain:sdkdir()
        if sdkdir then
            local includedir = path.join(sdkdir, "include")
            if os.isdir(includedir) then
                toolchain:add("includedirs", includedir)
            end
            local linkdir = path.join(sdkdir, "lib")
            if os.isdir(linkdir) then
                toolchain:add("linkdirs", linkdir)
            end
        end

        -- add bin search library for loading some dependent .dll files windows
        local bindir = toolchain:bindir()
        if bindir and is_host("windows") then
            toolchain:add("runenvs", "PATH", bindir)
        end
    end)
