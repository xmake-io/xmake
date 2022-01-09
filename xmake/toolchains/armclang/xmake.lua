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
    set_toolset("as", "armclang")

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
        -- replace function
        -- this function from https://blog.csdn.net/gouki04/article/details/88559872
        string.replace = function(s, pattern, repl)
            local i,j = string.find(s, pattern, 1, true)
            if i and j then
                local ret = {}
                local start = 1
                while i and j do 
                    table.insert(ret, string.sub(s, start, i-1))
                    table.insert(ret, repl)
                    start = j + 1
                    i,j = string.find(s, pattern, start , true )
                end
                table.insert(ret, string.sub(s, start))
                return table.concat(ret)
            end 
            return s
        end

        local arch         = toolchain:arch()
        local arch_lower   = arch:lower()
        local arch_replace = string.replace(arch_lower, "plus", "+")
        local arch_target  = ""

        -- convert for ldflag
        if arch_lower:startswith("cortex-m") then 
            arch_replace = string.replace(arch_replace, "cortex-m", "Cortex-M")
            arch_target  = "arm-arm-none-eabi"
        end
        if arch_lower:startswith("cortex-a") then 
            arch_replace = string.replace(arch_replace, "cortex-a", "Cortex-A")
            arch_target  = "aarch64-arm-none-eabi"
        end

        if arch_lower then
            toolchain:add("cxflags", "-target=" .. arch_target)
            toolchain:add("cxflags", "-mcpu=" .. arch_lower)
            toolchain:add("asflags", "-target=" .. arch_target)
            toolchain:add("asflags", "-mcpu=" .. arch_lower)
            toolchain:add("ldflags", "--cpu " .. arch_replace)
        end
    end)
