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

toolchain("iararm")
    set_kind("standalone")
    set_homepage("https://www.iar.com/products/architectures/arm/iar-embedded-workbench-for-arm/")
    set_description("IAR ARM C/C++ Compiler")

    set_toolset("cc", "iccarm")
    set_toolset("cxx", "iccarm")
    set_toolset("ld", "ilinkarm")
    set_toolset("sh", "ilinkarm")
    set_toolset("ar", "iarchive")
    set_toolset("as", "iccarm")

    on_check(function (toolchain)
        return import("lib.detect.find_tool")("iccarm")
    end)

    on_load(function (toolchain)
        local arch = toolchain:arch()
        if arch then
            toolchain:add("cxflags", "--cpu " .. arch)
            toolchain:add("asflags", "--cpu " .. arch)
            toolchain:add("ldflags", "--cpu " .. arch)
        end
    end)
