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
-- @author      retro98boy
-- @file        xmake.lua
--

toolchain("ccrh")
    set_kind("standalone")
    set_homepage("https://www.renesas.com")
    set_description("Renesas RH850 compiler")

    set_toolset("as", "ccrh")
    set_toolset("cc", "ccrh")
    set_toolset("ld", "rlink")
    set_toolset("ar", "rlink")

    on_check(function (toolchain)
        return import("lib.detect.find_tool")("ccrh")
    end)
