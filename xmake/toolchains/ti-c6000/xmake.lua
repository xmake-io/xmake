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

toolchain("ti-c6000")
    set_kind("standalone")
    set_homepage("https://www.ti.com")
    set_description("TI-CGT C6000 compiler")

    set_toolset("cc", "cl6x")
    set_toolset("cxx", "cl6x")
    set_toolset("ld", "cl6x")
    set_toolset("sh", "cl6x")
    set_toolset("ar", "ar6x")
    set_toolset("strip", "strip6x")
    set_toolset("as", "cl6x")

    on_check(function (toolchain)
        return import("lib.detect.find_tool")("cl6x")
    end)

    on_load(function (toolchain)
        local march = "-mv64+"
        if march then
            toolchain:add("cxflags", march)
            toolchain:add("mxflags", march)
            toolchain:add("asflags", march)
            toolchain:add("ldflags", march)
            toolchain:add("shflags", march)
        end
    end)
