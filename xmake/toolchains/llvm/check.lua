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
-- Copyright (C) 2015-2020, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        check.lua
--

-- imports
import("core.project.config")
import("detect.sdks.find_cross_toolchain")

-- check the cross toolchain
function main(toolchain)

    -- get sdk directory
    local sdkdir = config.get("sdk")
    local bindir = config.get("bin")
    if not sdkdir and not bindir then
        if toolchain:is_plat("linux") and os.isfile("/usr/bin/llvm-ar") then
            sdkdir = "/usr"
        end
    end

    -- find cross toolchain
    local cross_toolchain = find_cross_toolchain(sdkdir, {bindir = bindir})
    if cross_toolchain then
        config.set("cross", cross_toolchain.cross, {readonly = true, force = true})
        config.set("bin", cross_toolchain.bindir, {readonly = true, force = true})
    else
        raise("llvm toolchain not found!")
    end
    return cross_toolchain
end
