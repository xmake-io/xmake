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
toolchain("zigcc")
    set_kind("standalone")
    set_homepage("https://ziglang.org/")
    set_description("Use zig cc/c++ as C/C++ Compiler")

    on_check(function (toolchain)
        import("lib.detect.find_tool")

        -- @see https://github.com/xmake-io/xmake/issues/5610
        local function _setup_zigcc_wrapper(zig)
            local script_suffix = is_host("windows") and ".cmd" or ""
            for _, tool in ipairs({"cc", "c++", "ar", "ranlib", "lib", "ld.lld", "lld-link", "wasm-ld", "objcopy", "dlltool", "rc"}) do
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
            _setup_zigcc_wrapper(zig)
            toolchain:config_set("zig", zig)
            toolchain:config_set("zig_version", zig_version)
            return true
        end
    end)

    on_load(function (toolchain)
        import("private.utils.toolchain", {alias = "toolchain_utils"})

        -- set toolset
        -- we patch target to `zig cc` to fix has_flags. see https://github.com/xmake-io/xmake/issues/955#issuecomment-766929692
        toolchain:set("toolset", "cc",       toolchain:config("toolset_cc"))
        toolchain:set("toolset", "cxx",      toolchain:config("toolset_c++"))
        toolchain:set("toolset", "ld",       toolchain:config("toolset_c++"))
        toolchain:set("toolset", "sh",       toolchain:config("toolset_c++"))
        toolchain:set("toolset", "ar",       toolchain:config("toolset_ar"))
        toolchain:set("toolset", "ranlib",   toolchain:config("toolset_ranlib"))
        toolchain:set("toolset", "lib",      toolchain:config("toolset_lib"))
        toolchain:set("toolset", "ld.lld",   toolchain:config("toolset_ld.lld"))
        toolchain:set("toolset", "lld-link", toolchain:config("toolset_lld-link"))
        toolchain:set("toolset", "wasm-ld",  toolchain:config("toolset_wasm-ld"))
        toolchain:set("toolset", "objcopy",  toolchain:config("toolset_objcopy"))
        toolchain:set("toolset", "as",       toolchain:config("toolset_cc"))
        toolchain:set("toolset", "dlltool",  toolchain:config("toolset_dlltool"))
        toolchain:set("toolset", "mrc",      toolchain:config("toolset_rc"))

        local target = toolchain_utils.get_zig_target(toolchain)
        if target then
            toolchain:add("asflags", "-target", target)
            toolchain:add("cxflags", "-target", target)
            toolchain:add("shflags", "-target", target)
            toolchain:add("ldflags", "-target", target)
        end
    end)
