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

toolchain("verilator")
    set_homepage("https://verilator.org/")
    set_description("Verilator open-source SystemVerilog simulator and lint system")

    on_check(function (toolchain)
        import("lib.detect.find_tool")
        local paths = {}
        for _, package in ipairs(toolchain:packages()) do
            local envs = package:envs()
            if envs then
                table.join2(paths, envs.PATH)
            end
        end
        local verilator = find_tool("verilator", {paths = paths})
        if verilator and verilator.program then
            toolchain:config_set("verilator", verilator.program)
            cprint("${dim}checking for verilator ... ${color.success}%s", path.filename(verilator.program))
        else
            cprint("${dim}checking for verilator ... ${color.nothing}${text.nothing}")
            raise("verilator not found!")
        end
        toolchain:configs_save()
        return true
    end)

    on_load(function (toolchain)
        if is_host("windows") then
            for _, package in ipairs(toolchain:packages()) do
                local envs = package:envs()
                if envs then
                    local verilator_root = envs.VERILATOR_ROOT
                    if verilator_root then
                        toolchain:add("runenvs", "VERILATOR_ROOT", table.unwrap(verilator_root))
                        break
                    end
                end
            end
        end
    end)
