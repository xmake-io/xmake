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

-- imports
import("core.project.config")
import("lib.detect.find_tool")
import("private.utils.toolchain", {alias = "toolchain_utils"})

function _check_clang(toolchain, vcvars, suffix)
    local paths
    local pathenv = os.getenv("PATH")
    if pathenv then
        paths = path.splitenv(pathenv)
    end
    local result = find_tool("clang" .. suffix, {force = true, paths = paths, envs = vcvars})
    if result then
        cprint("checking for LLVM Clang C/C++ Compiler (%s) ... ${color.success}", toolchain:arch())
    end
    return result
end

function main(toolchain, suffix)

    -- only for windows or linux (msvc-wine)
    if not is_host("windows", "linux") then
        return
    end

    -- @see https://github.com/xmake-io/xmake/pull/679
    local cc  = path.basename(config.get("cc") or "clang"):lower()
    local cxx = path.basename(config.get("cxx") or "clang++"):lower()
    if cc == "clang" or cxx == "clang" or cxx == "clang++" then
        local check = function (toolchain, vcvars)
            return _check_clang(toolchain, vcvars, suffix)
        end
        local sdkdir = toolchain:sdkdir()
        if sdkdir then
            return toolchain_utils.check_vc_build_tools(toolchain, sdkdir, _check_clang)
        else
            for _, package in ipairs(toolchain:packages()) do
                local installdir = package:installdir()
                if installdir and os.isdir(installdir) then
                    local result = toolchain_utils.check_vc_build_tools(toolchain, installdir, _check_clang)
                    if result then
                        return result
                    end
                end
            end
            return toolchain_utils.check_vstudio(toolchain, _check_clang)
        end
    end
end

