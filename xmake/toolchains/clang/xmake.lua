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
        
    -- set toolsets
    set_toolsets("cc", "clang")
    set_toolsets("cxx", "clang", "clang++")
    set_toolsets("ld", "clang++", "clang")
    set_toolsets("sh", "clang++", "clang")
    set_toolsets("ar", "ar")
    set_toolsets("ex", "ex")
    set_toolsets("strip", "strip")
    set_toolsets("mm", "clang")
    set_toolsets("mxx", "clang", "clang++")
    set_toolsets("as", "clang")

    -- check toolchain
    on_check(function (toolchain)
        return import("lib.detect.find_tool")("clang")
    end)
