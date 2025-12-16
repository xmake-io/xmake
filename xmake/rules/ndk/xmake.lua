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
-- Copyright (C) 2015-present, Xmake Open Source Community.
--
-- @author      keosu
-- @file        xmake.lua
--

-- define rule: build android native app with NDK
--
-- @code
-- target("test")
--     set_kind("binary")
--     add_rules("android.native_app", {
--        android_sdk_version = "35",
--        android_manifest = "android/AndroidManifest.xml",
--        android_res = "android/res",
--        android_assets = "android/assets",
--        keystore = "android/debug.jks",
--        keystore_pass = "123456",
--        package_name = "com.raylib.demo"
--     })
-- @endcode
--
rule("android.native_app")

    -- we must set_kind and add some glue files to target
    on_load("load")

    -- generate android apk package
    after_build("package")

    -- install android package with adb
    on_install("install")

    -- uninstall android package with adb
    on_uninstall("uninstall")

    -- run android app through adb
    on_run("run")
