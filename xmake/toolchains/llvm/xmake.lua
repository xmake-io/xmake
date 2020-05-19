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
       
    -- check toolchain
    on_check("check")

    -- on load
    on_load(function (toolchain)

        -- set toolsets
        toolchain:set("toolsets", "cc", "clang")
        toolchain:set("toolsets", "cxx", "clang", "clang++")
        toolchain:set("toolsets", "cpp", "clang -E")
        toolchain:set("toolsets", "as", "clang")
        toolchain:set("toolsets", "ld", "clang++", "clang")
        toolchain:set("toolsets", "sh", "clang++", "clang")
        toolchain:set("toolsets", "ar", "llvm-ar")
        toolchain:set("toolsets", "ex", "llvm-ar")
        toolchain:set("toolsets", "ranlib", "llvm-ranlib")
        toolchain:set("toolsets", "strip", "llvm-strip")

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
            os.addenv("PATH", bindir)
        end
    end)
