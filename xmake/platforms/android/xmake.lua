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
-- Copyright (C) 2015-2020, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        xmake.lua
--

-- define platform
platform("android")

    -- set os
    set_os("android")

    -- set hosts
    set_hosts("macosx", "linux", "windows")

    -- set archs, we use the latest android abi provided in android ndk now.
    -- we will continue to support the old abi architectures for old version ndk.
    -- e.g. armv5te(armeabi), armv7-a(armeabi-v7a), mips, mips64, i386
    --
    -- @see https://developer.android.google.cn/ndk/guides/abis
    -- @note The NDK previously supported ARMv5 (armeabi) and 32-bit and 64-bit MIPS, but this support has been removed in NDK r17.
    --
    set_archs("armeabi", "armeabi-v7a", "arm64-v8a", "x86", "x86_64", "mips", "mip64")

    -- set formats
    set_formats("static", "lib$(name).a")
    set_formats("object", "$(name).o")
    set_formats("shared", "lib$(name).so")
    set_formats("symbol", "$(name).sym")

    -- on check
    on_check(function (platform)
        import("core.project.config")
        local arch = config.get("arch")
        if not arch then
            config.set("arch", "armeabi-v7a")
            cprint("checking for architecture ... ${color.success}%s", config.get("arch"))
        end
    end)

    -- set toolchains
    set_toolchains("envs", "ndk", "rust")

    -- set menu
    set_menu {
                config =
                {
                    {category = "Android Configuration"                                                 }
                ,   {nil, "ndk",            "kv", nil,          "The NDK Directory"                     }
                ,   {nil, "ndk_sdkver",     "kv", "auto",       "The SDK Version for NDK"               }
                ,   {nil, "android_sdk",    "kv", nil,          "The Android SDK Directory"             }
                ,   {nil, "build_toolver",  "kv", nil,          "The Build Tool Version of Android SDK" }
                ,   {nil, "ndk_stdcxx",     "kv", true,         "Use stdc++ library for NDK"            }
                ,   {nil, "ndk_cxxstl",     "kv", nil,          "The stdc++ stl library for NDK",
                                                                "    - c++_static",
                                                                "    - c++_shared",
                                                                "    - gnustl_static",
                                                                "    - gnustl_shared",
                                                                "    - stlport_shared",
                                                                "    - stlport_static"                  }
                }

            ,   global =
                {
                    {category = "Android Configuration"                                                 }
                ,   {nil, "ndk",            "kv", nil,          "The NDK Directory"                     }
                ,   {nil, "ndk_sdkver",     "kv", "auto",       "The SDK Version for NDK"               }
                ,   {nil, "android_sdk",    "kv", nil,          "The Android SDK Directory"             }
                ,   {nil, "build_toolver",  "kv", nil,          "The Build Tool Version of Android SDK" }
                }
            }



