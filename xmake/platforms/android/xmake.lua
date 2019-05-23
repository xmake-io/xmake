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
-- Copyright (C) 2015 - 2019, TBOOX Open Source Group.
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

    -- set archs
    set_archs("armv7-a", "arm64-v8a", "armv5te", "mips", "mips64", "i386", "x86_64")

    -- set formats
    set_formats {static = "lib$(name).a", object = "$(name).o", shared = "lib$(name).so", symbol = "$(name).sym"}

    -- on check project configuration
    on_config_check("config")

    -- on load
    on_load("load")

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
                                                                "    - gnustl_shared",
                                                                "    - gnustl_static",
                                                                "    - llvmstl_shared",
                                                                "    - llvmstl_static",
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



