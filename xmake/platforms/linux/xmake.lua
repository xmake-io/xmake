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
platform("linux")

    -- set os
    set_os("linux")

    -- set hosts
    set_hosts("macosx", "linux", "windows")

    -- set archs
    set_archs("i386", "x86_64", "armv7", "armv7s", "arm64-v8a", "mips", "mips64", "mipsel", "mips64el")

    -- set formats
    set_formats("static", "lib$(name).a")
    set_formats("object", "$(name).o")
    set_formats("shared", "lib$(name).so")
    set_formats("symbol", "$(name).sym")

    -- set install directory
    set_installdir("/usr/local")

    -- on check
    on_check(function (platform)
        import("core.project.config")
        local arch = config.get("arch")
        if not arch then
            config.set("arch", os.arch())
            cprint("checking for architecture ... ${color.success}%s", config.get("arch"))
        end
    end)

    -- set toolchains
    set_toolchains("envs", "cross", "gcc", "clang", "yasm", "nasm", "fasm", "cuda", "dlang", "go", "rust", "gfortran", "zig")

    -- set menu
    set_menu {
                config =
                {
                    {category = "Cuda SDK Configuration"                                            }
                ,   {nil, "cuda",           "kv", "auto",       "The Cuda SDK Directory"            }
                ,   {category = "Qt SDK Configuration"                                              }
                ,   {nil, "qt",             "kv", "auto",       "The Qt SDK Directory"              }
                ,   {nil, "qt_sdkver",      "kv", "auto",       "The Qt SDK Version"                }
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


