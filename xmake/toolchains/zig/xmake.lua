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
    set_kind("standalone")
    set_homepage("https://ziglang.org/")
    set_description("Zig Programming Language Compiler")

    on_check(function (toolchain)
        import("lib.detect.find_tool")

        -- @see https://github.com/xmake-io/xmake/issues/5610
        function _setup_zigcc_wrapper(zig)
            local script_suffix = is_host("windows") and ".cmd" or ""
            for _, tool in ipairs({"cc", "c++", "ar", "ranlib", "objcopy"}) do
                local wrapper_path = path.join(os.tmpdir(), "zigcc", tool) .. script_suffix
                if not os.isfile(wrapper_path) then
                    if is_host("windows") then
                        io.writefile(wrapper_path, ("@echo off\n\"%s\" %s %%*"):format(zig, tool))
                    else
                        io.writefile(wrapper_path, ("#!/bin/bash\nexec \"%s\" %s \"$@\""):format(zig, tool))
                        os.runv("chmod", {"+x", wrapper_path})
                    end
                end
                if (tool == "cc" or tool == "c++") and wrapper_path then
                    wrapper_path = "zig_cc@" .. wrapper_path
                end
                toolchain:config_set("toolset_" .. tool, wrapper_path)
            end
        end

        local paths = {}
        for _, package in ipairs(toolchain:packages()) do
            local envs = package:envs()
            if envs then
                table.join2(paths, envs.PATH)
            end
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
            _setup_zigcc_wrapper(zig)
            toolchain:config_set("zig", zig)
            toolchain:config_set("zig_version", zig_version)
            toolchain:configs_save()
            return true
        end
    end)

    on_load(function (toolchain)
        import("core.base.semver")

        -- set toolset
        -- we patch target to `zig cc` to fix has_flags. see https://github.com/xmake-io/xmake/issues/955#issuecomment-766929692
        local zig = toolchain:config("zig") or "zig"
        local zig_version = toolchain:config("zig_version")
        if toolchain:config("zigcc") ~= false then
            -- we can use `set_toolchains("zig", {zigcc = false})` to disable zigcc
            -- @see https://github.com/xmake-io/xmake/issues/3251
            toolchain:set("toolset", "cc",      toolchain:config("toolset_cc"))
            toolchain:set("toolset", "cxx",     toolchain:config("toolset_c++"))
            toolchain:set("toolset", "ld",      toolchain:config("toolset_c++"))
            toolchain:set("toolset", "sh",      toolchain:config("toolset_c++"))
            toolchain:set("toolset", "ar",      toolchain:config("toolset_ar"))
            toolchain:set("toolset", "ranlib",  toolchain:config("toolset_ranlib"))
            toolchain:set("toolset", "objcopy", toolchain:config("toolset_objcopy"))
            toolchain:set("toolset", "as",      toolchain:config("toolset_cc"))
        end
        toolchain:set("toolset", "zc",   zig)
        toolchain:set("toolset", "zcar", zig)
        toolchain:set("toolset", "zcld", zig)
        toolchain:set("toolset", "zcsh", zig)

        -- init arch
        if toolchain:is_arch("arm64", "arm64-v8a") then
            arch = "aarch64"
        elseif toolchain:is_arch("arm", "armv7") then
            arch = "arm"
        elseif toolchain:is_arch("i386", "x86") then
            if zig_version and semver.compare(zig_version, "0.11") >= 0 then
                arch = "x86"
            else
                arch = "i386"
            end
        elseif toolchain:is_arch("riscv64") then
            arch = "riscv64"
        elseif toolchain:is_arch("loong64") then
            arch = "loongarch64"
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
        local target = toolchain:cross()
        if target == nil then
            if toolchain:is_plat("cross") then
                -- xmake f -p cross --toolchain=zig --cross=mips64el-linux-gnuabi64
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
        end
        if target then
            toolchain:add("asflags", "-target", target)
            toolchain:add("cxflags", "-target", target)
            toolchain:add("shflags", "-target", target)
            toolchain:add("ldflags", "-target", target)
            toolchain:add("zcflags", "-target", target)
            toolchain:add("zcldflags", "-target", target)
            toolchain:add("zcshflags", "-target", target)
        end

        -- @see https://github.com/ziglang/zig/issues/5825
        if toolchain:is_plat("windows") then
            toolchain:add("zcldflags", "--subsystem console")
            toolchain:add("zcldflags", "-lkernel32", "-lntdll")
        end
    end)
