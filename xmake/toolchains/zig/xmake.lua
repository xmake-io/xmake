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
toolchain("zig")

    -- set homepage
    set_homepage("https://ziglang.org/")
    set_description("Zig Programming Language Compiler")

    -- on check
    on_check(function (toolchain)
        import("lib.detect.find_tool")
        local paths = {}
        for _, package in ipairs(toolchain:packages()) do
            local envs = package:get("envs")
            if envs then
                table.join2(paths, envs.PATH)
            end
        end
        local zig = get_config("zc")
        if not zig then
            zig = find_tool("zig", {force = true, paths = paths})
            if zig and zig.program then
                zig = zig.program
            end
        end
        if zig then
            toolchain:config_set("zig", zig)
            toolchain:configs_save()
            return true
        end
    end)

    -- on load
    on_load(function (toolchain)

        -- set toolset
        -- we patch target to `zig cc` to fix has_flags. see https://github.com/xmake-io/xmake/issues/955#issuecomment-766929692
        local zig = toolchain:config("zig") or "zig"
        if toolchain:config("zigcc") ~= false then
            -- we can use `set_toolchains("zig", {zigcc = false})` to disable zigcc
            -- @see https://github.com/xmake-io/xmake/issues/3251
            toolchain:set("toolset", "cc",    zig .. " cc")
            toolchain:set("toolset", "cxx",   zig .. " c++")
            toolchain:set("toolset", "ld",    zig .. " c++")
            toolchain:set("toolset", "sh",    zig .. " c++")
        end
        toolchain:set("toolset", "ar",   "$(env ZC)", zig)
        toolchain:set("toolset", "zc",   "$(env ZC)", zig)
        toolchain:set("toolset", "zcar", "$(env ZC)", zig)
        toolchain:set("toolset", "zcld", "$(env ZC)", zig)
        toolchain:set("toolset", "zcsh", "$(env ZC)", zig)

        -- init arch
        if toolchain:is_arch("arm64", "arm64-v8a") then
            arch = "aarch64"
        elseif toolchain:is_arch("arm", "armv7") then
            arch = "arm"
        elseif toolchain:is_arch("i386", "x86") then
            arch = "i386"
        elseif toolchain:is_arch("riscv64") then
            arch = "riscv64"
        elseif toolchain:is_arch("mips.*") then
            arch = toolchain:arch()
        elseif toolchain:is_arch("ppc64") then
            arch = "powerpc64"
        elseif toolchain:is_arch("ppc") then
            arch = "powerpc"
        elseif toolchain:is_arch("s390x") then
            arch = "s390x"
        else
            arch = "x86_64"
        end

        -- init target
        local target
        if toolchain:is_plat("cross") then
            -- xmake f -p cross --toolchain=zig --cross=mips64el-linux-gnuabi64
            target = toolchain:cross()
        elseif toolchain:is_plat("macosx") then
            --@see https://github.com/ziglang/zig/issues/14226
            target = arch .. "-macos-none"
        elseif toolchain:is_plat("linux") then
            if arch == "arm" then
                target = "arm-linux-gnueabi"
            elseif arch == "mips64" or arch == "mips64el" then
                target = arch .. "-linux-gnuabi64"
            else
                target = arch .. "-linux-gnu"
            end
        elseif toolchain:is_plat("windows") then
            target = arch .. "-windows-msvc"
        elseif toolchain:is_plat("mingw") then
            target = arch .. "-windows-gnu"
        end
        if target then
            toolchain:add("zig_cc.cxflags", "-target", target)
            toolchain:add("zig_cc.shflags", "-target", target)
            toolchain:add("zig_cc.ldflags", "-target", target)
            toolchain:add("zig_cxx.cxflags", "-target", target)
            toolchain:add("zig_cxx.shflags", "-target", target)
            toolchain:add("zig_cxx.ldflags", "-target", target)
            toolchain:add("zcflags", "-target", target)
            toolchain:add("zcldflags", "-target", target)
            toolchain:add("zcshflags", "-target", target)
        end

        -- @see https://github.com/ziglang/zig/issues/5825
        if toolchain:is_plat("windows") then
            toolchain:add("zcldflags", "--subsystem console")
            toolchain:add("syslinks", "kernel32", "ntdll")
        end
    end)
