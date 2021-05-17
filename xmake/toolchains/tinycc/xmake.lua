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

-- define toolchain
toolchain("tinycc")

    -- set homepage
    set_homepage("https://bellard.org/tcc/")
    set_description("Tiny C Compiler")

    -- mark as standalone toolchain
    set_kind("standalone")

    -- check toolchain
    on_check(function (toolchain)

        -- imports
        import("core.project.config")
        import("lib.detect.find_tool")

        -- find tcc
        local paths = {toolchain:bindir()}
        local sdkdir = toolchain:sdkdir()
        if sdkdir then
            table.insert(paths, path.join(sdkdir, "bin"))
        end
        for _, package in ipairs(toolchain:packages()) do
            local installdir = package:installdir()
            if installdir then
                table.insert(paths, path.join(installdir, "bin"))
            end
        end
        local tcc = find_tool("tcc", {paths = paths})
        if tcc then
            toolchain:config_set("tcc", tcc.program)
            toolchain:configs_save()
            return true
        end
    end)

    -- on load
    on_load(function (toolchain)

        -- imports
        import("core.project.config")

        -- add march flags
        local march
        if toolchain:is_arch("x86_64", "x64") then
            march = "-m64"
        elseif toolchain:is_arch("i386", "x86") then
            march = "-m32"
        end
        if march then
            toolchain:add("cxflags", march)
            toolchain:add("mxflags", march)
            toolchain:add("asflags", march)
            toolchain:add("ldflags", march)
            toolchain:add("shflags", march)
        end

        -- add toolset
        local tcc = toolchain:config("tcc") or "tcc"
        toolchain:add("toolset", "cc", tcc)
        toolchain:add("toolset", "ld", tcc)
        toolchain:add("toolset", "sh", tcc)
        toolchain:add("toolset", "ar", tcc)

        -- add includedirs and linkdirs
        for _, package in ipairs(toolchain:packages()) do
            local installdir = package:installdir()
            if installdir then
                toolchain:add("sysincludedirs", path.join(installdir, "include"))
                toolchain:add("linkdirs", path.join(installdir, "lib"))
            end
        end
    end)
