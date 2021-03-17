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
import("detect.sdks.find_ndk")
import("detect.sdks.find_android_sdk")

-- check the ndk toolchain
function _check_ndk(toolchain)
    local ndk = find_ndk(toolchain:config("ndk") or config.get("ndk"), {force = true, verbose = true})
    if ndk then
        toolchain:config_set("ndk", ndk.sdkdir)
        toolchain:config_set("bindir", ndk.bindir)
        toolchain:config_set("cross", ndk.cross)
        toolchain:config_set("gcc_toolchain", ndk.gcc_toolchain)
        toolchain:config_set("ndkver", ndk.ndkver)
        toolchain:config_set("ndk_sdkver", ndk.sdkver)
        toolchain:config_set("ndk_toolchains_ver", ndk.toolchains_ver)
        toolchain:config_set("ndk_sysroot", ndk.sysroot)
        toolchain:configs_save()
    else
        -- failed
        cprint("${bright color.error}please run:")
        cprint("    - xmake config --ndk=xxx")
        cprint("or  - xmake global --ndk=xxx")
        raise()
    end
end

-- check the android sdk
function _check_android_sdk(toolchain)
    local sdk = find_android_sdk(toolchain:config("android_sdk") or config.get("android_sdk"), {force = true, verbose = true})
    if sdk then
        toolchain:config_set("android_sdk", sdk.sdkdir)
        toolchain:config_set("build_toolver", sdk.build_toolver)
        toolchain:configs_save()
    end
end

-- main entry
function main(toolchain)
    _check_android_sdk(toolchain)
    _check_ndk(toolchain)
    return true
end
