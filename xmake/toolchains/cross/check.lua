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
import("lib.detect.find_file")

-- find liblto_plugin.so path for gcc
function _find_gcc_liblto_plugin_path(cross_toolchain)
    local gcc = find_file((cross_toolchain.cross or "*-") .. "gcc", cross_toolchain.bindir)
    if gcc then
        local plugin_path
        local outdata = try { function() return os.iorunv(gcc, {"-print-prog-name=lto-wrapper"}) end }
        if outdata then
            local lto_plugindir = path.directory(outdata:trim())
            if os.isdir(lto_plugindir) then
                if is_host("windows") then
                    plugin_path = find_file("liblto_plugin*.dll", lto_plugindir)
                else
                    plugin_path = find_file("liblto_plugin.so", lto_plugindir)
                end
            end
        end
        return plugin_path
    end
end

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

        -- find lto_plugin.so path for gcc
        -- @see https://github.com/xmake-io/xmake/issues/5015
        -- https://github.com/xmake-io/xmake/issues/5051
        local lto_plugin = _find_gcc_liblto_plugin_path(cross_toolchain)
        if lto_plugin then
            toolchain:config_set("lto_plugin", lto_plugin)
        end
    else
        raise("cross toolchain not found!")
    end
    return cross_toolchain
end

