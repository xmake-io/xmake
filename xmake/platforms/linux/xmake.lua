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
-- @file        xmake.lua
--

-- define platform
platform("linux")

    -- set os
    set_os("linux")

    -- set hosts
    set_hosts("macosx", "linux", "windows", "bsd")

    -- set archs
    set_archs("i386", "x86_64", "armv7", "armv7s", "arm64-v8a", "mips", "mips64", "mipsel", "mips64el")

    -- set formats
    set_formats("static", "lib$(name).a")
    set_formats("object", "$(name).o")
    set_formats("shared", "lib$(name).so")
    set_formats("symbol", "$(name).sym")

    -- set install directory
    set_installdir("/usr/local")

    -- set toolchains
    set_toolchains("envs", "cross", "gcc", "clang", "yasm", "nasm", "fasm", "cuda", "go", "rust", "swift", "gfortran", "zig", "fpc", "nim")

    -- set menu
    set_menu {
                config =
                {
                    {category = "Cuda SDK Configuration"                                            }
                ,   {nil, "cuda",           "kv", "auto",       "The Cuda SDK Directory"            }
                ,   {category = "Qt SDK Configuration"                                              }
                ,   {nil, "qt",             "kv", "auto",       "The Qt SDK Directory"              }
                ,   {nil, "qt_sdkver",      "kv", "auto",       "The Qt SDK Version"                }
                ,   {nil, "qmake",          "kv", "auto",       "The Qt QMake Tool"                 }
                ,   {category = "Vcpkg Configuration"                                               }
                ,   {nil, "vcpkg",          "kv", "auto",       "The Vcpkg Directory"               }
                }

            ,   global =
                {
                    {category = "Cuda SDK Configuration"                                            }
                ,   {nil, "cuda",           "kv", "auto",       "The Cuda SDK Directory"            }
                ,   {category = "Qt SDK Configuration"                                              }
                ,   {nil, "qt",             "kv", "auto",       "The Qt SDK Directory"              }
                ,   {category = "Vcpkg Configuration"                                               }
                ,   {nil, "vcpkg",          "kv", "auto",       "The Vcpkg Directory"               }
                }
            }


