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
-- Copyright (C) 2015-present, TBOOX Open Sousce Group.
--
-- @author      ruki
-- @file        xmake.lua
--

-- define toolchain
toolchain("swift")

    -- set homepage
    set_homepage("https://swift.org/")
    set_description("Swift Programming Language Compiler")

    -- set toolset
    set_toolset("sc",   "$(env SC)", "swiftc")
    set_toolset("scld", "$(env SC)", "swiftc")
    set_toolset("scsh", "$(env SC)", "swiftc")

    -- on load
    on_load(function (toolchain)
        toolchain:set("scshflags", "")
        toolchain:set("scldflags", "")
    end)
