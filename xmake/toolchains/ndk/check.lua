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
import("detect.sdks.find_ndk")
import("detect.sdks.find_android_sdk")

-- check the ndk toolchain
function _check_ndk()
    local ndk = find_ndk(config.get("ndk"), {force = true, verbose = true})
    if ndk then
        config.set("ndk", ndk.sdkdir, {force = true, readonly = true})
        config.set("bin", ndk.bindir, {force = true, readonly = true})
        config.set("cross", ndk.cross, {force = true, readonly = true})
        config.set("gcc_toolchain", ndk.gcc_toolchain, {force = true, readonly = true})
    else
        -- failed
        cprint("${bright color.error}please run:")
        cprint("    - xmake config --ndk=xxx")
        cprint("or  - xmake global --ndk=xxx")
        raise()
    end
end

-- check the android sdk
function _check_android_sdk()
    local sdk = find_android_sdk(config.get("android_sdk"), {force = true, verbose = true})
    if sdk then
        config.set("sdk", sdk.sdkdir, {force = true, readonly = true})
    end
end

-- main entry
function main(toolchain)
    _check_android_sdk()
    _check_ndk()
    return true
end
