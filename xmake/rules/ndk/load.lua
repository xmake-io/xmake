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

-- main entry
function main (target)

    local toolchain_ndk = target:toolchain("ndk")

    local ndk_root = toolchain_ndk:config("ndk")
    if not ndk_root then
        raise("NDK path not set! Please set NDK path properly.")
    end

    local native_app_glue_file = path.join(ndk_root, "sources", "android", "native_app_glue", "android_native_app_glue.c")

    -- Add glue file to target
    local conf = target:extraconf("rules", "android.native_app")
    target:add("files", native_app_glue_file)
    target:add("includedirs", native_app_glue_path)

    target:set("kind", "shared")

end
