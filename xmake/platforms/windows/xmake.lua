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
platform("windows")

    -- set os
    set_os("windows")

    -- set hosts
    set_hosts("windows")

    -- set archs
    set_archs("x86", "x64")

    -- set formats
    set_formats {static = "$(name).lib", object = "$(name).obj", shared = "$(name).dll", binary = "$(name).exe", symbol = "$(name).pdb"}

    -- on check project configuration
    on_config_check("config")

    -- on check global configuration
    on_global_check("global")

    -- on environment enter
    on_environment_enter("environment.enter")

    -- on environment leave
    on_environment_leave("environment.leave")

    -- on load
    on_load("load")

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
                ,   {category = "Cuda SDK Configuration"                                            }
                ,   {nil, "cuda",       "kv", "auto", "The Cuda SDK Directory"                      }
                ,   {category = "Qt SDK Configuration"                                              }
                ,   {nil, "qt",         "kv", "auto", "The Qt SDK Directory"                        }
                ,   {nil, "qt_sdkver",  "kv", "auto", "The Qt SDK Version"                          }
                ,   {category = "WDK Configuration"                                                 }
                ,   {nil, "wdk",        "kv", "auto", "The WDK Directory"                           }
                ,   {nil, "wdk_sdkver", "kv", "auto", "The WDK Version"                             }
                ,   {nil, "wdk_winver", "kv", "auto", "The WDK Windows Version",
                                                      "  - win10_rs3",
                                                      "  - win10",
                                                      "  - win81",
                                                      "  - win8",
                                                      "  - win7",
                                                      "  - win7_[sp1|sp2|sp3]"                      }
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


