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
import("core.project.config")
import("detect.sdks.find_cross_toolchain")

-- check the cross toolchain
function main(toolchain)

    -- is cross?
    local sdkdir = toolchain:sdkdir()
    local bindir = toolchain:bindir()
    local cross  = toolchain:cross()
    if not sdkdir and not bindir and not cross and not toolchain:packages() then
        return
    end

    -- find cross toolchain from external envirnoment
    local cross_toolchain = find_cross_toolchain(sdkdir, {bindir = bindir, cross = cross})
    if not cross_toolchain then
        -- find it from packages
        for _, package in ipairs(toolchain:packages()) do
            local installdir = package:installdir()
            if installdir and os.isdir(installdir) then
                cross_toolchain = find_cross_toolchain(installdir, {cross = cross})
                if cross_toolchain then
                    break
                end
            end
        end
    end
    if cross_toolchain then
        toolchain:config_set("cross", cross_toolchain.cross)
        toolchain:config_set("bindir", cross_toolchain.bindir)
        toolchain:config_set("sdkdir", cross_toolchain.sdkdir)
        toolchain:configs_save()
        -- init default target os
        if not config.get("target_os") then
            config.set("target_os", "linux", {readonly = true, force = true})
        end
    else
        raise("cross toolchain not found!")
    end
    return cross_toolchain
end

