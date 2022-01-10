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
-- Copyright (C) 2015-present, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        check.lua
--

-- imports
import("core.base.option")
import("core.project.config")
import("detect.sdks.find_iccenv")
import("lib.detect.find_tool")

-- check intel on windows
function _check_intel_on_windows(toolchain)

    -- have been checked?
    local varsall = toolchain:config("varsall")
    if varsall then
        return true
    end

    -- find intel c/c++ compiler environment
    local iccenv = find_iccenv()
    if iccenv and iccenv.iclvars then
        local iclvarsall = iccenv.iclvars
        local iclenv = iclvarsall[toolchain:arch()]
        if iclenv and iclenv.PATH and iclenv.INCLUDE and iclenv.LIB then
            local tool = find_tool("icl.exe", {force = true, envs = iclenv, version = true})
            if tool then
                cprint("checking for Intel C/C++ Compiler (%s) ... ${color.success}${text.success}", toolchain:arch())
                toolchain:config_set("varsall", iclvarsall)
                toolchain:configs_save()
                return true
            end
        end
    end
end

-- check intel on linux
function _check_intel_on_linux(toolchain)
    local iccenv = toolchain:config("iccenv")
    if iccenv then
        return true
    end
    iccenv = find_iccenv()
    if iccenv then
        local ldname = is_host("macosx") and "DYLD_LIBRARY_PATH" or "LD_LIBRARY_PATH"
        local tool = find_tool("icc", {force = true, envs = {[ldname] = iccenv.libdir}, paths = iccenv.bindir})
        if tool then
            cprint("checking for Intel C/C++ Compiler (%s) ... ${color.success}${text.success}", toolchain:arch())
            toolchain:config_set("iccenv", iccenv)
            toolchain:config_set("bindir", iccenv.bindir)
            toolchain:configs_save()
            return true
        end
        return true
    end
end

-- main entry
function main(toolchain)
    if is_host("windows") then
        return _check_intel_on_windows(toolchain)
    else
        return _check_intel_on_linux(toolchain)
    end
end

