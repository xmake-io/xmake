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

import("detect.sdks.find_vstudio")
import("lib.detect.find_tool")
import("core.project.config")

function _check_vc_build_tools(toolchain, sdkdir, suffix)
    local opt = {}
    opt.sdkdir = sdkdir
    opt.vs_toolset = toolchain:config("vs_toolset") or config.get("vs_toolset")
    opt.vs_sdkver = toolchain:config("vs_sdkver") or config.get("vs_sdkver")

    local vcvarsall = find_vstudio.find_build_tools(opt)
    if not vcvarsall then
        return
    end

    local vcvars = vcvarsall[toolchain:arch()]
    if vcvars and vcvars.PATH and vcvars.INCLUDE and vcvars.LIB then
        -- save vcvars
        toolchain:config_set("vcvars", vcvars)
        toolchain:config_set("vcarchs", table.orderkeys(vcvarsall))
        toolchain:config_set("vs_toolset", vcvars.VCToolsVersion)
        toolchain:config_set("vs_sdkver", vcvars.WindowsSDKVersion)

        -- check compiler
        local paths
        local pathenv = os.getenv("PATH")
        if pathenv then
            paths = path.splitenv(pathenv)
        end
        local clang = find_tool("clang" .. suffix, {version = true, force = true, paths = paths, envs = vcvars})
        if clang and clang.version then
            cprint("checking for LLVM Clang C/C++ Compiler (%s) version ... ${color.success}%s", toolchain:arch(), clang.version)
        end
        return vcvars
    end
end

function main(toolchain, suffix)

    -- only for windows or linux (msvc-wine)
    if not is_host("windows", "linux") then
        return
    end

    local sdkdir = toolchain:sdkdir()
    if sdkdir then
        return _check_vc_build_tools(toolchain, sdkdir, suffix)
    end
end
