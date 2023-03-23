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
platform("windows")

    -- set os
    set_os("windows")

    -- set hosts
    set_hosts("windows")

    -- set archs
    set_archs("x86", "x64", "arm64")

    -- set formats
    set_formats("static", "$(name).lib")
    set_formats("object", "$(name).obj")
    set_formats("shared", "$(name).dll")
    set_formats("binary", "$(name).exe")
    set_formats("symbol", "$(name).pdb")

    -- set toolchains
    set_toolchains("msvc", "clang", "yasm", "nasm", "cuda", "rust", "swift", "go", "gfortran", "zig", "fpc", "nim")

    -- set menu
    set_menu {
                config =
                {
                    {category = "Visual Studio SDK Configuration"                                   }
                ,   {nil, "vs",         "kv", "auto", "The Microsoft Visual Studio"
                                                    , "  e.g. --vs=2017"                            }
                ,   {nil, "vs_toolset", "kv", nil,    "The Microsoft Visual Studio Toolset Version"
                                                    , "  e.g. --vs_toolset=14.0"                    }
                ,   {nil, "vs_sdkver",  "kv", nil,    "The Windows SDK Version of Visual Studio"
                                                    , "  e.g. --vs_sdkver=10.0.15063.0"             }
                ,   {nil, "vs_runtime", "kv", nil,    "The Runtime library of Visual Studio"
                                                    , values = {"MT", "MTd", "MD", "MDd"}           }
                ,   {category = "Cuda SDK Configuration"                                            }
                ,   {nil, "cuda",       "kv", "auto", "The Cuda SDK Directory"                      }
                ,   {category = "Qt SDK Configuration"                                              }
                ,   {nil, "qt",         "kv", "auto", "The Qt SDK Directory"                        }
                ,   {nil, "qt_sdkver",  "kv", "auto", "The Qt SDK Version"                          }
                ,   {nil, "qmake",      "kv", "auto", "The Qt QMake Tool"                           }
                ,   {category = "WDK Configuration"                                                 }
                ,   {nil, "wdk",        "kv", "auto", "The WDK Directory"                           }
                ,   {nil, "wdk_sdkver", "kv", "auto", "The WDK Version"                             }
                ,   {nil, "wdk_winver", "kv", "auto", "The WDK Windows Version"
                                                    , values = function (complete)
                                                        if complete then
                                                            return {"win10_rs3", "win10", "win81", "win8", "win7_sp3", "win7_sp2", "win7_sp1", "win7"}
                                                        else
                                                            return {"win10[|_rs3]", "win81", "win8", "win7[|_sp1|_sp2|_sp3]"}
                                                        end
                                                    end                                             }
                ,   {category = "Vcpkg Configuration"                                               }
                ,   {nil, "vcpkg",      "kv", "auto", "The Vcpkg Directory"                         }
                }

            ,   global =
                {
                    {category = "Visual Studio SDK Configuration"                                   }
                ,   {nil, "vs",         "kv", "auto", "The Microsoft Visual Studio"                 }
                ,   {category = "Cuda SDK Configuration"                                            }
                ,   {nil, "cuda",       "kv", "auto", "The Cuda SDK Directory"                      }
                ,   {category = "Qt SDK Configuration"                                              }
                ,   {nil, "qt",         "kv", "auto", "The Qt SDK Directory"                        }
                ,   {category = "WDK Configuration"                                                 }
                ,   {nil, "wdk",        "kv", "auto", "The WDK Directory"                           }
                ,   {category = "Vcpkg Configuration"                                               }
                ,   {nil, "vcpkg",      "kv", "auto", "The Vcpkg Directory"                         }
                }
            }


