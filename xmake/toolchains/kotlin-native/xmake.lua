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

toolchain("kotlin-native")
    set_kind("standalone")
    set_homepage("https://kotlinlang.org")
    set_description("The Kotlin Programming Language Compiler. ")

    set_toolset("kc",   "$(env KC)", "kotlinc-native")
    set_toolset("kcld", "$(env KC)", "kotlinc-native")
    set_toolset("kcsh", "$(env KC)", "kotlinc-native")
    set_toolset("kcar", "$(env KC)", "kotlinc-native")

    on_check(function (toolchain)
        import("lib.detect.find_tool")

        local paths = {}
        for _, package in ipairs(toolchain:packages()) do
            local envs = package:envs()
            if envs then
                table.join2(paths, envs.PATH)
            end
        end
        if toolchain:bindir() then
            table.insert(paths, toolchain:bindir())
        end
        local kotlinc_native = find_tool("kotlinc-native", {paths = paths})
        if kotlinc_native and kotlinc_native.program then
            kotlinc_native = kotlinc_native.program
        end
        if kotlinc_native then
            if path.is_absolute(kotlinc_native) then
                local bindir = path.directory(kotlinc_native)
                toolchain:config_set("bindir", bindir)
                toolchain:config_set("sdkdir", path.directory(bindir))
            end
            toolchain:configs_save()
            return true
        end
    end)

    on_load(function (toolchain)
        -- TODO
    end)
