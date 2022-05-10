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
-- @author      DawnMagnet
-- @file        xmake.lua
--

toolchain("c51")

    set_homepage("https://www.keil.com/c51/")
    set_description("Keil development tools for the 8051 Microcontroller Architecture")

    set_kind("cross")
    set_kind("standalone")

    set_toolset("cc", "c51")
    set_toolset("cxx", "c51")
    set_toolset("ld", "bl51")

    on_check(function (toolchain)
        import("lib.detect.find_tool")
        import("detect.sdks.find_c51")
        local c51 = find_c51()
        if c51 and c51.sdkdir and find_tool("c51") then
            toolchain:config_set("sdkdir", c51.sdkdir)
            toolchain:configs_save()
            return true
        end
    end)