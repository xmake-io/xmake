-- !A cross-platform build utility based on Lua
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
-- @author      Xmake Open Source Community
-- @file        xmake.lua
--

import("core.tool.toolchain")

function main(target)
    local conf = target:extraconf("rules", "android.native_app") 
    local android_sdk_version = conf.android_sdk_version
    local android_manifest = conf.android_manifest
    local android_res = conf.android_res
    local android_assets = conf.android_assets
    local keystore = conf.keystore
    local keystore_pass = conf.keystore_pass

    assert(android_sdk_version, "android sdk version not set")
    assert(android_manifest, "android manifest not set")

    cprint("${green}[Android][Package]${white} Starting...")

    local tmp_path = path.join(target:targetdir(), "temp")
    os.mkdir(tmp_path) 
    os.mkdir(path.join(tmp_path, "lib")) 
    os.mkdir(path.join(tmp_path, "lib", target:arch()))

    -- copy the target library to temp folder with name libmain.so
    local libfile = path.join(tmp_path, "lib", target:arch(), "libmain.so")
    os.cp(target:targetfile(), libfile)

  
    -- get android tool path
    local android_sdkdir = target:toolchain("ndk"):config("android_sdk")
    local android_build_toolver = target:toolchain("ndk"):config("build_toolver")
    local sdk_tool_path = path.join(android_sdkdir, "build-tools", android_build_toolver)

    local aapt = path.join(sdk_tool_path, "aapt" .. (is_host("windows") and ".exe" or ""))    
    local zipalign = path.join(sdk_tool_path, "zipalign" .. (is_host("windows") and ".exe" or ""))
    local apksigner = path.join(sdk_tool_path, "apksigner" .. (is_host("windows") and ".bat" or ""))

    -- pack resources 
    local resonly_apk = path.join(tmp_path, "res_only.apk")    
    local androidjar = path.join(android_sdkdir, "platforms", string.format("android-%s", android_sdk_version),
        "android.jar")
    assert(os.exists(androidjar), "%s not found", androidjar)
    local aapt_argv = {"package", "-f", "-M", android_manifest, "-I", androidjar, "-F", resonly_apk}

    if android_res ~= nil and os.exists(android_res) then
        table.insert(aapt_argv, "-S")
        table.insert(aapt_argv, android_res)
    end

    if android_assets ~= nil and os.exists(android_assets) and os.emptydir(android_assets) == false then
        table.insert(aapt_argv, "-A")
        table.insert(aapt_argv, android_assets)
    end

    cprint("${green}[Android][Packing resources]${white} Create a resource only apk...")
    os.vrunv(aapt, aapt_argv)

    -- pack libs
    cprint("${green}[Android][Packing library]${white} Adding library to res_only.apk...")
    os.vrunv(aapt, {"add", "res_only.apk", "lib/" .. target:arch() .."/libmain.so"},  {curdir = tmp_path})

    -- align apk
    local aligned_apk = path.join(tmp_path, "unsigned.apk") 
    local zipalign_argv = {"-f", "4", "res_only.apk", "unsigned.apk"}

    cprint("${green}[Android][Align apk]${white} Save to " .. aligned_apk .. "...")
    os.vrunv(zipalign, zipalign_argv,  {curdir = tmp_path})

    -- sign apk
    local final_apk = path.join(target:targetdir(), target:basename() .. ".apk")

    local apksigner_argv = {"sign", "--ks", keystore, "--ks-pass", string.format("pass:%s", keystore_pass), "--out",
                            final_apk, "--in", aligned_apk}
    cprint("${green}[Android][Signing apk]${white} Save to " .. final_apk .. "...")
    os.vrunv(apksigner, apksigner_argv)

    cprint("${green}[Android][Package]${white} Done!")
    
end
