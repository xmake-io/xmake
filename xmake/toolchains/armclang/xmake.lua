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

toolchain("armclang")

    set_homepage("https://www2.keil.com/mdk5/compiler/6")
    set_description("ARM Compiler Version 6 of Keil MDK")

    set_kind("cross")

    set_toolset("cc", "armclang")
    set_toolset("cxx", "armclang")
    set_toolset("ld", "armlink")
    set_toolset("ar", "armar")
    set_toolset("as", "armasm")

    on_check(function (toolchain)
        import("lib.detect.find_tool")
        import("detect.sdks.find_mdk")
        local mdk = find_mdk()
        if mdk and mdk.sdkdir_armclang and find_tool("armclang") then
            toolchain:config_set("sdkdir", mdk.sdkdir_armclang)
            toolchain:configs_save()
            return true
        end
    end)

    on_load(function (toolchain)
        local arch = toolchain:arch()
        if arch then
            local arch_cpu     = arch:lower()
            local arch_cpu_ld  = ""
            local arch_target  = ""
            if arch_cpu:startswith("cortex-m") then
                arch_cpu_ld = arch_cpu:replace("cortex-m", "Cortex-M", {plain = true})
                arch_target  = "arm-arm-none-eabi"
            end
            if arch_cpu:startswith("cortex-a") then
                arch_cpu_ld = arch_cpu:replace("cortex-a", "Cortex-A", {plain = true})
                arch_target  = "aarch64-arm-none-eabi"
            end
            toolchain:add("cxflags", "-target=" .. arch_target)
            toolchain:add("cxflags", "-mcpu="   .. arch_cpu)
            toolchain:add("asflags", "-target=" .. arch_target)
            toolchain:add("asflags", "--cpu="   .. arch_cpu)
            toolchain:add("ldflags", "--cpu "   .. arch_cpu_ld)
        end
    end)

