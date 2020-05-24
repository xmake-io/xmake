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
    local xcode = find_xcode(config.get("xcode"), {force = not optional, verbose = true, plat = config.get("plat"), arch = config.get("arch")})
    if xcode then
        config.set("xcode", xcode.sdkdir, {force = true, readonly = true})
    else
        return false
    end

    -- save target minver
    local xcode_sdkver = config.get("xcode_sdkver")
    local target_minver = config.get("target_minver")
    if xcode_sdkver and not target_minver then
        target_minver = xcode_sdkver
        if is_plat("macosx") then
            local macos_ver = macos.version()
            if macos_ver then
                target_minver = macos_ver:major() .. "." .. macos_ver:minor()
            end
        end
        config.set("target_minver", target_minver)
    end
    return true
end
