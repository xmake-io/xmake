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
-- @author      wuzhenqing
-- @file        check.lua
--

-- imports
import("lib.detect.find_tool")

-- map host architecture to CANN host tool directory
function _host_archdir(arch)
    local host_archdirs = {
        x86_64 = "x86_64-linux"
    ,   x64 = "x86_64-linux"
    ,   arm64 = "aarch64-linux"
    ,   aarch64 = "aarch64-linux"
    }
    return host_archdirs[arch]
end

-- check the ascendc toolchain
function main(toolchain)
    if not toolchain:is_plat("linux") then
        return false
    end

    -- resolve sdkdir: --sdk= > ASCEND_HOME_PATH > ASCEND_TOOLKIT_HOME
    local sdkroot = toolchain:sdkdir()
    if not sdkroot then
        sdkroot = os.getenv("ASCEND_HOME_PATH") or os.getenv("ASCEND_TOOLKIT_HOME")
    end
    if not sdkroot or not os.isdir(sdkroot) then
        return false
    end
    sdkroot = path.absolute(sdkroot)

    -- map host arch to CANN host directory
    local host_arch = os.arch()
    local host_archdir = _host_archdir(host_arch)
    if not host_archdir then
        return false
    end

    local hostroot = path.join(sdkroot, host_archdir)
    if not os.isdir(hostroot) then
        return false
    end

    -- check required executables
    local bindir = path.join(hostroot, "bin")
    local bisheng_bin = path.join(bindir, "bisheng")
    local llvm_ar = path.join(bindir, "llvm-ar")
    if not os.isexec(bisheng_bin) or not os.isexec(llvm_ar) then
        return false
    end

    -- ensure bisheng can load its own shared libraries during version check
    local host_libdir = path.join(hostroot, "lib64")
    local ld_library_path = os.getenv("LD_LIBRARY_PATH") or ""
    local envs = {
        LD_LIBRARY_PATH = ld_library_path ~= "" and
            (host_libdir .. path.envsep() .. ld_library_path) or host_libdir
    }

    -- use find_tool (unified interface) instead of find_bisheng directly
    local result = find_tool("bisheng", {program = bisheng_bin, version = true, envs = envs})
    if not result or not result.program then
        return false
    end

    toolchain:config_set("sdkdir", sdkroot)
    toolchain:config_set("bindir", bindir)
    toolchain:config_set("hostroot", hostroot)
    cprint("checking for Huawei Ascend C Toolchain (host: %s) ... ${color.success}${text.success}", host_arch)
    return true
end
