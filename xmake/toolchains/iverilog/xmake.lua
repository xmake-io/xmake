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

toolchain("iverilog")
    set_homepage("https://steveicarus.github.io/iverilog/")
    set_description("Icarus Verilog")

    set_kind("standalone")

    on_check(function (toolchain)
        import("lib.detect.find_tool")
        local paths = {}
        for _, package in ipairs(toolchain:packages()) do
            local envs = package:envs()
            if envs then
                table.join2(paths, envs.PATH)
            end
        end
        local iverilog = find_tool("iverilog", {paths = paths})
        if iverilog and iverilog.program then
            toolchain:config_set("iverilog", iverilog.program)
            cprint("${dim}checking for iverilog ... ${color.success}%s", path.filename(iverilog.program))
        else
            cprint("${dim}checking for iverilog ... ${color.nothing}${text.nothing}")
            raise("iverilog not found!")
        end
        local vvp = find_tool("vvp", {paths = paths})
        if vvp and vvp.program then
            toolchain:config_set("vvp", vvp.program)
            cprint("${dim}checking for vvp ... ${color.success}%s", path.filename(vvp.program))
        else
            cprint("${dim}checking for vvp ... ${color.nothing}${text.nothing}")
            raise("iverilog not found!")
        end
        toolchain:configs_save()
        return true
    end)
