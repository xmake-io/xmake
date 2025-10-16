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
function toolchain_gcc(version)
local suffix = ""
if version then
    suffix = suffix .. "-" .. version
end
toolchain("gcc" .. suffix)
    set_kind("standalone")
    set_homepage("https://gcc.gnu.org/")
    set_description("GNU Compiler Collection" .. (version and (" (" .. version .. ")") or ""))
    set_runtimes("stdc++_static", "stdc++_shared")

    set_toolset("cc", "gcc" .. suffix)
    set_toolset("cxx", "g++" .. suffix, "gcc" .. suffix)
    set_toolset("ld", "g++" .. suffix, "gcc" .. suffix)
    set_toolset("sh", "g++" .. suffix, "gcc" .. suffix)
    set_toolset("ar", "ar")
    set_toolset("strip", "strip")
    set_toolset("objcopy", "objcopy")
    set_toolset("ranlib", "ranlib")
    set_toolset("mm", "gcc" .. suffix)
    set_toolset("mxx", "g++" .. suffix, "gcc" .. suffix)
    set_toolset("as", "gcc" .. suffix)

    on_check(function (toolchain)
        return import("lib.detect.find_tool")("gcc", {program = "gcc" .. suffix})
    end)

    on_load(function (toolchain)
        import("core.base.option")

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

        local host_arch = os.arch()
        local target_arch = toolchain:arch()

        if host_arch == target_arch then
            -- Early exit: prevents further configuration of this toolchain
            return
        elseif option.get("verbose") then
            cprint("${bright yellow}cross compiling from %s to %s", host_arch, target_arch)
        end

        local target
        if toolchain:is_arch("x86_64", "x64") then
            target = "x86_64"
        elseif toolchain:is_arch("i386", "x86", "i686") then
            target = "i686"
        elseif toolchain:is_arch("arm64", "aarch64") then
            target = "aarch64"
        elseif toolchain:is_arch("arm") then
            target = "armv7"
        end

        -- TODO: Add support for more platforms, such as mingw.
        if target and toolchain:is_plat("linux") then
            target = target .. "-linux-gnu-"
            toolchain:set("toolset", "cc", target .. "gcc" .. suffix)
            toolchain:set("toolset", "cxx", target .. "g++" .. suffix, "gcc" .. suffix)
            toolchain:set("toolset", "ld", target .. "g++" .. suffix, "gcc" .. suffix)
            toolchain:set("toolset", "sh", target .. "g++" .. suffix, "gcc" .. suffix)
        end
    end)
end
toolchain_gcc()
