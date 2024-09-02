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

toolchain("nim")
    set_homepage("https://nim-lang.org/")
    set_description("Nim Programming Language Compiler")

    on_check(function (toolchain)
        import("lib.detect.find_tool")
        local paths = {}
        for _, package in ipairs(toolchain:packages()) do
            local envs = package:envs()
            if envs then
                table.join2(paths, envs.PATH)
            end
        end
        local nim = get_config("nc")
        if not nim then
            nim = find_tool("nim", {force = true, paths = paths})
            if nim and nim.program then
                nim = nim.program
            end
        end
        if nim then
            toolchain:config_set("nim", nim)
            toolchain:configs_save()
            return true
        end
    end)

    on_load(function (toolchain)
        local nim = toolchain:config("nim") or "nim"
        toolchain:set("toolset", "nc",   "$(env NC)", nim)
        toolchain:set("toolset", "ncld", "$(env NC)", nim)
        toolchain:set("toolset", "ncsh", "$(env NC)", nim)
        toolchain:set("toolset", "ncar", "$(env NC)", nim)

        if toolchain:is_plat("windows") then
            toolchain:set("ncflags", "--cc:vcc")
            local msvc = import("core.tool.toolchain", {anonymous = true}).load("msvc", {plat = toolchain:plat(), arch = toolchain:arch()})
            for name, value in pairs(msvc:get("runenvs")) do
                 toolchain:add("runenvs", name, value)
            end
        end
        toolchain:set("ncshflags", "")
        toolchain:set("ncldflags", "")
    end)

