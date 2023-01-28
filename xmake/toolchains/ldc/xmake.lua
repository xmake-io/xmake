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
toolchain("ldc")
    set_homepage("https://github.com/ldc-developers/ldc")
    set_description("The LLVM-based D Compiler.")

    on_check("check")

    on_load(function (toolchain)
        toolchain:add("toolset", "dc",   "ldc2")
        toolchain:add("toolset", "dcld", "ldc2")
        toolchain:add("toolset", "dcsh", "ldc2")
        toolchain:add("toolset", "dcar", "ldc2")

        local march
        if toolchain:is_arch("x86_64", "x64") then
            march = "-m64"
        elseif toolchain:is_arch("i386", "x86") then
            march = "-m32"
        end
        toolchain:add("dcflags",   march or "")
        toolchain:add("dcshflags", march or "")
        toolchain:add("dcldflags", march or "")
    end)
