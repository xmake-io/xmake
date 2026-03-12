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
-- Copyright (C) 2015-present, Xmake Open Source Community.
--
-- @author      ruki
-- @file        xmake.lua
--

-- define toolchain
toolchain("zig")
    set_homepage("https://ziglang.org/")
    set_description("Zig Programming Language Compiler")

    on_check(function (toolchain)
        import("lib.detect.find_tool")

        local paths = {}
        for _, package in ipairs(toolchain:packages()) do
            local envs = package:envs()
            if envs then
                table.join2(paths, envs.PATH)
            end
        end
        local sdkdir = toolchain:sdkdir()
        if sdkdir then
            table.insert(paths, sdkdir)
        end

        local zig = get_config("zc")
        local zig_version
        if not zig then
            zig = find_tool("zig", {force = true, version = true, paths = paths})
            if zig and zig.program then
                zig_version = zig.version
                zig = zig.program
            end
        end
        if zig then
            toolchain:config_set("zig", zig)
            toolchain:config_set("zig_version", zig_version)
            return true
        end
    end)

    on_load(function (toolchain)
        import("private.utils.toolchain", {alias = "toolchain_utils"})

        local zig = toolchain:config("zig") or "zig"
        toolchain:set("toolset", "zc",   zig)
        toolchain:set("toolset", "zcar", zig)
        toolchain:set("toolset", "zcld", zig)
        toolchain:set("toolset", "zcsh", zig)

        local target = toolchain_utils.get_zig_target(toolchain)
        if target then
            toolchain:add("zcflags", "-target", target)
            toolchain:add("zcldflags", "-target", target)
            toolchain:add("zcshflags", "-target", target)
        end

        -- @see https://github.com/ziglang/zig/issues/5825
        if toolchain:is_plat("windows") then
            toolchain:add("zcldflags", "--subsystem console")
            toolchain:add("zcldflags", "-lkernel32", "-lntdll")
            toolchain:add("zcshflags", "-lc", "-lkernel32", "-lntdll")
        end
    end)
