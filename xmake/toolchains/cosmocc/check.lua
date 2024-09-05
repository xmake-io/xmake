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
import("lib.detect.find_path")
import("lib.detect.find_tool")
import("detect.sdks.find_cross_toolchain")

-- check the cross toolchain
function main(toolchain)

    -- get sdk directory
    local sdkdir = toolchain:sdkdir()
    local bindir = toolchain:bindir()

    -- find cross toolchain from external envirnoment
    local envs
    local cross_toolchain
    -- find it from packages first, because we need bind msys2 envirnoments from package.
    for _, package in ipairs(toolchain:packages()) do
        local installdir = package:installdir()
        if installdir and os.isdir(installdir) then
            cross_toolchain = find_cross_toolchain(installdir)
            if cross_toolchain then
                -- we need to bind msys2 shell envirnoments for calling cosmocc,
                -- @see https://github.com/xmake-io/xmake/issues/5552
                if is_subhost("windows") then
                    envs = package:envs()
                end
                break
            end
        end
    end
    if not cross_toolchain then
        cross_toolchain = find_cross_toolchain(sdkdir, {bindir = bindir})
    end
    if not cross_toolchain then
        local cosmocc = find_tool("cosmocc", {force = true})
        if cosmocc and cosmocc.program then
            local bindir = path.directory(cosmocc.program)
            local sdkdir = path.directory(bindir)
            cross_toolchain = {bindir = bindir, sdkdir = sdkdir}
        end
    end
    if cross_toolchain then
        toolchain:config_set("cross", cross_toolchain.cross)
        toolchain:config_set("bindir", cross_toolchain.bindir)
        toolchain:config_set("sdkdir", cross_toolchain.sdkdir)
        if envs then
            toolchain:config_set("envs", envs)
        end
        toolchain:configs_save()
    else
        raise("cosmocc toolchain not found!")
    end
    return cross_toolchain
end

