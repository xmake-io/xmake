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
toolchain("zig")

    -- set homepage
    set_homepage("https://ziglang.org/")
    set_description("Zig Programming Language Compiler")
        
    -- set toolset
    set_toolset("zc",   "$(env ZC)", "zig")
    set_toolset("zcar", "$(env ZC)", "zig")
    set_toolset("zcld", "$(env ZC)", "zig")
    set_toolset("zcsh", "$(env ZC)", "zig")

    -- on load
    on_load(function (toolchain)
        local march
        if is_plat("macosx") then
            march = "x86_64-macosx-gnu"
        end
        if march then
            toolchain:add("zcflags", "-target", march)
        end
    end)
