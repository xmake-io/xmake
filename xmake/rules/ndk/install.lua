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

function main(target)

    local android_sdkdir = target:toolchain("ndk"):config("android_sdk")
    local adb = path.join(android_sdkdir, "platform-tools", "adb")

    local final_apk = path.join(target:targetdir(), target:basename() .. ".apk")
    assert(os.exists(final_apk)) 

    cprint("${green}[Android][Install] try to install apk ...")
    os.vrunv(adb, {"install", final_apk})

    cprint("${green}[Android][Install] done.")

end
