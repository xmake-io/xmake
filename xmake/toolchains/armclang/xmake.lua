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

    on_check(function (toolchain)
        import("core.base.semver")
        import("lib.detect.find_tool")
        import("detect.sdks.find_mdk")
        local mdk = find_mdk()
        if mdk and mdk.sdkdir_armclang then
            toolchain:config_set("sdkdir", mdk.sdkdir_armclang)
            -- different assembler choices for different versions of armclang
            local armclang = find_tool("armclang", {version = true, force = true, paths = path.join(mdk.sdkdir_armclang, "bin")})
            if armclang and armclang.version and semver.compare(armclang.version, "6.13") > 0 then
                toolchain:config_set("toolset_as", "armclang")
            else
                toolchain:config_set("toolset_as", "armasm")
            end
            toolchain:configs_save()
            return true
        end
    end)

    on_load(function (toolchain)
        local arch = toolchain:arch()
        if arch then
            local arch_cpu     = arch:lower()
            local as = toolchain:config("toolset_as")
            toolchain:set("toolset", "as", as)
            toolchain:add("cxflags", "--target=arm-arm-none-eabi")
            toolchain:add("cxflags", "-mcpu="   .. arch_cpu)
            if as == "armclang" then
                toolchain:add("asflags", "--target=arm-arm-none-eabi")
                toolchain:add("asflags", "-mcpu=" .. arch_cpu)
                toolchain:add("asflags", "-masm=auto")
            else
                toolchain:add("asflags", "--cpu=" .. arch_cpu)
            end
            toolchain:add("ldflags", "--cpu="   .. arch_cpu)
        end
    end)

