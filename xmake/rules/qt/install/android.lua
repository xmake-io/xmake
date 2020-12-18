--!A cross-platform build utility based on Lua
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
-- @file        android.lua
--

-- install application package for android
function main(target, opt)

    -- get target apk path
    local target_apk = path.join(path.directory(target:targetfile()), target:basename() .. ".apk")
    assert(os.isfile(target_apk), "apk not found, please build %s first!", target:name())

    -- show install info
    print("installing %s ..", target_apk)

    -- get android sdk directory
    local android_sdkdir = path.translate(assert(get_config("android_sdk"), "please run `xmake f --android_sdk=xxx` to set the android sdk directory!"))

    -- get adb
    local adb = path.join(android_sdkdir, "platform-tools", "adb" .. (is_host("windows") and ".exe" or ""))
    if not os.isexec(adb) then
        adb = "adb"
    end

    -- install apk to device
    os.execv(adb, {"install", "-r", target_apk})
end
