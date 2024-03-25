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
import("detect.sdks.find_hdk")

-- check the hdk toolchain
function _check_hdk(toolchain)
    local hdk
    for _, package in ipairs(toolchain:packages()) do
        local installdir = package:installdir()
        if installdir and os.isdir(installdir) then
            hdk = find_hdk(installdir, {force = true, verbose = option.get("verbose")})
            if hdk then
                break
            end
        end
    end
    if not hdk then
        hdk = find_hdk(toolchain:config("hdk") or config.get("sdk"), {force = true, verbose = true})
    end
    if hdk then
        toolchain:config_set("sdkdir", hdk.sdkdir)
        toolchain:config_set("bindir", hdk.bindir)
        toolchain:config_set("sysroot", hdk.sysroot)
        toolchain:configs_save()
        return true
    else
        --[[TODO we also need to add this tips when use remote hdk toolchain
        -- failed
        cprint("${bright color.error}please run:")
        cprint("    - xmake config --hdk=xxx")
        cprint("or  - xmake global --hdk=xxx")
        raise()]]
    end
end

function main(toolchain)
    return _check_hdk(toolchain)
end
