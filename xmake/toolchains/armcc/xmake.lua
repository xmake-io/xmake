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

toolchain("armcc")

    set_homepage("https://www2.keil.com/mdk5/compiler/5")
    set_description("ARM Compiler Version 5 of Keil MDK")

    set_kind("cross")

    set_toolset("cc", "armcc")
    set_toolset("cxx", "armcc")
    set_toolset("ld", "armlink")
    set_toolset("ar", "armar")
    set_toolset("as", "armasm")

    on_check(function (toolchain)
        import("lib.detect.find_tool")
        import("detect.sdks.find_mdk")
        local mdk = find_mdk()
        if mdk and mdk.sdkdir_armcc and find_tool("armcc") then
            toolchain:config_set("sdkdir", mdk.sdkdir_armcc)
            toolchain:configs_save()
            return true
        end
    end)


    on_load(function (toolchain)
        local arch = toolchain:arch()
        if arch then
            toolchain:add("cxflags", "--cpu " .. arch)
            toolchain:add("asflags", "--cpu " .. arch)
            toolchain:add("ldflags", "--cpu " .. arch)
        end
    end)
