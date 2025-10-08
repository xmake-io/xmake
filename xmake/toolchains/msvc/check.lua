--!A cross-toolchain build utility based on Lua
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
-- @file        check.lua
--

-- imports
import("core.base.option")
import("core.project.config")
import("lib.detect.find_tool")
import("private.utils.toolchain", {alias = "toolchain_utils"})

function _check_cl(toolchain, vcvars)
    local cl = find_tool("cl.exe", {force = true, envs = vcvars})
    if cl then
        cprint("checking for Microsoft C/C++ Compiler (%s) ... ${color.success}${text.success}", toolchain:arch())
    end
    return cl
end

function main(toolchain)

    -- only for windows or linux (msvc-wine)
    if not is_host("windows", "linux") then
        return
    end

    -- @see https://github.com/xmake-io/xmake/pull/679
    local cc  = path.basename(config.get("cc") or "cl"):lower()
    local cxx = path.basename(config.get("cxx") or "cl"):lower()
    local mrc = path.basename(config.get("mrc") or "rc"):lower()
    if cc == "cl" or cxx == "cl" or mrc == "rc" then
        local sdkdir = toolchain:sdkdir()
        if sdkdir then
            sdkdir = toolchain_utils.check_vc_build_tools(toolchain, sdkdir, _check_cl)
        end
        if not sdkdir then
            for _, package in ipairs(toolchain:packages()) do
                local installdir = package:installdir()
                if installdir and os.isdir(installdir) then
                    local result = toolchain_utils.check_vc_build_tools(toolchain, installdir, _check_cl)
                    if result then
                        return result
                    end
                end
            end
            sdkdir = toolchain_utils.check_vstudio(toolchain, _check_cl)
        end
        return sdkdir
    end
end

