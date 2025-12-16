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
-- @file        run.lua
--

-- imports
import("core.base.tty")
import("install", {alias = "install_app"})

-- main entry
function main(target)

    -- install it first
    install_app(target)

    local conf = target:extraconf("rules", "android.native_app")
    local package_name = conf.package_name
    local activity_name = conf.activity_name or "android.app.NativeActivity"

    local android_sdkdir = target:toolchain("ndk"):config("android_sdk")
    local adb = path.join(android_sdkdir, "platform-tools", "adb")

    local run_argv = {"shell", "am", "start", "-n", package_name .. "/" .. activity_name}

    cprint("running %s ...", package_name)
    os.vrunv(adb, run_argv)

    -- show logcat
    local logcat_argv = {"logcat"}
    if io.isatty() and (tty.has_color8() or tty.has_color256()) then
        table.insert(logcat_argv, "-v")
        table.insert(logcat_argv, "color")
    end
    local logcat_filters = conf.logcat_filters
    if logcat_filters then
        table.insert(logcat_argv, "-s")
        for _, filter in ipairs(logcat_filters) do
            table.insert(logcat_argv, filter)
        end
    end
    os.execv(adb, logcat_argv)
end
