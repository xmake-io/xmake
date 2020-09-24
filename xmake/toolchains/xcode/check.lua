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
import("core.base.option")
import("core.project.config")
import("detect.sdks.find_xcode")

-- main entry
function main(toolchain)

    -- find xcode
    local xcode = find_xcode(config.get("xcode"), {force = not optional, verbose = true, plat = toolchain:plat(), arch = toolchain:arch()})
    if xcode then
        config.set("xcode", xcode.sdkdir, {force = true, readonly = true})
    else
        return false
    end

    -- save target minver
    --
    -- @note we need to differentiate the version for the system,
    -- because the xcode toolchain of iphoneos/macosx may need to be used at the same time.
    --
    -- e.g.
    --
    -- target("test")
    --     set_toolchains("xcode", {plat = os.host(), arch = os.arch()})
    --
    local xcode_sdkver = toolchain:is_plat(config.plat()) and config.get("xcode_sdkver")
    if not xcode_sdkver then
        xcode_sdkver = config.get("xcode_sdkver_" .. toolchain:plat())
    end
    local target_minver = toolchain:is_plat(config.plat()) and config.get("target_minver")
    if not target_minver then
        target_minver = config.get("target_minver_" .. toolchain:plat())
    end
    if xcode_sdkver and not target_minver then
        target_minver = xcode_sdkver
        if toolchain:is_plat("macosx") then
            local macos_ver = macos.version()
            if macos_ver then
                target_minver = macos_ver:major() .. "." .. macos_ver:minor()
            end
        end
    end
    config.set("target_minver_" .. toolchain:plat(), target_minver)
    return true
end
