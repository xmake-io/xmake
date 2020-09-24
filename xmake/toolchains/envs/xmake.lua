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
toolchain("envs")

    -- set description
    set_description("Environment variables toolchain")

    -- set toolset
    set_toolset("cc",    "$(env CC)")
    set_toolset("cxx",   "$(env CXX)")
    set_toolset("ld",    "$(env LD)", "$(env CXX)")
    set_toolset("sh",    "$(env SH)", "$(env LD)", "$(env CXX)")
    set_toolset("ar",    "$(env AR)")
    set_toolset("ex",    "$(env EX)", "$(env AR)")
    set_toolset("strip", "$(env STRIP)")
    set_toolset("ranlib","$(env RANLIB)")
    set_toolset("mm",    "$(env MM)")
    set_toolset("mxx",   "$(env MXX)")
    set_toolset("as",    "$(env AS)")
    set_toolset("sc",    "$(env SC)")

