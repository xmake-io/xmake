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
import("detect.sdks.find_ascend")

-- check the ascendc toolchain
function main(toolchain)
    if not toolchain:is_plat("linux") then
        return false
    end

    -- locate the Ascend SDK and derive its host layout
    local ascend = find_ascend(toolchain:sdkdir())
    if not ascend then
        return false
    end

    -- llvm-ar must sit next to bisheng (used as the static linker)
    if not os.isexec(path.join(ascend.bindir, "llvm-ar")) then
        return false
    end

    -- probe bisheng to confirm it actually runs (catches broken installs).
    -- pass bindir via paths and inject LD_LIBRARY_PATH so bisheng can load
    -- its own shared libraries during the version probe.
    local ld = os.getenv("LD_LIBRARY_PATH") or ""
    local result = find_tool("bisheng", {
        paths = {ascend.bindir},
        envs = {LD_LIBRARY_PATH = ld ~= "" and (ascend.libdir .. path.envsep() .. ld) or ascend.libdir},
        version = true})
    if not result or not result.program then
        return false
    end

    toolchain:config_set("sdkdir", ascend.sdkdir)
    toolchain:config_set("bindir", ascend.bindir)
    toolchain:config_set("hostroot", ascend.hostroot)
    cprint("checking for Huawei Ascend C Toolchain (host: %s) ... ${color.success}${text.success}", ascend.host_archdir)
    return true
end
