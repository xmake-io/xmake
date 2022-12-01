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

-- clang-cl toolchain
--
-- @param vs    the vs version
--
-- @code
-- target("test")
--     ...
--     set_toolchains("clang-cl")
--     set_toolchains("clang-cl", {vs = "2019"})
-- @endcode
--
toolchain("clang-cl")

    -- set homepage
    set_homepage("https://visualstudio.microsoft.com")
    set_description("LLVM Clang C/C++ Compiler compatible with msvc")

    -- mark as standalone toolchain
    set_kind("standalone")

    -- check toolchain
    on_check("check")

    -- load toolchain
    on_load("load")
