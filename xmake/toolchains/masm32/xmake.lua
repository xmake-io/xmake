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

toolchain("masm32")
    set_kind("standalone")
    set_homepage("https://www.masm32.com")
    set_description("The MASM32 SDK")

    set_toolset("as", "ml.exe")
    set_toolset("mrc", "rc.exe")
    set_toolset("ld", "link.exe")
    set_toolset("sh", "link.exe")
    set_toolset("ar", "link.exe")

    on_check(function (toolchain)
        import("lib.detect.find_tool")
        import("detect.sdks.find_masm32")
        local masm32 = find_masm32()
        if masm32 and masm32.sdkdir and masm32.bindir and find_tool("ml.exe", {program = path.join(masm32.bindir, "ml.exe")}) then
            toolchain:config_set("sdkdir", masm32.sdkdir)
            toolchain:config_set("bindir", masm32.bindir)
            toolchain:configs_save()
            return true
        end
    end)

    on_load(function (toolchain)
        toolchain:arch_set("x86")
        local sdkdir = toolchain:sdkdir()
        if sdkdir then
            toolchain:add("includedirs", path.join(sdkdir, "include"))
            toolchain:add("linkdirs", path.join(sdkdir, "lib"))
        end
        toolchain:add("asflags", "/coff")
        toolchain:add("syslinks", "user32", "kernel32")
    end)
