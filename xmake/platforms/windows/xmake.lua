--!A cross-platform build utility based on Lua
--
-- Licensed to the Apache Software Foundation (ASF) under one
-- or more contributor license agreements.  See the NOTICE file
-- distributed with this work for additional information
-- regarding copyright ownership.  The ASF licenses this file
-- to you under the Apache License, Version 2.0 (the
-- "License"); you may not use this file except in compliance
-- with the License.  You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- 
-- Copyright (C) 2015 - 2018, TBOOX Open Source Group.
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

    -- set environment
    set_environment("environment")

    -- set formats
    set_formats {static = "$(name).lib", object = "$(name).obj", shared = "$(name).dll", binary = "$(name).exe", symbol = "$(name).pdb"}

    -- on check
    on_check("check")

    -- on load
    on_load(function (platform)

        -- imports
        import("core.project.config")

        -- init flags for architecture
        local arch = config.get("arch") or os.arch()

        -- init flags for asm
        platform:add("yasm.asflags", "-f", arch == "x64" and "win64" or "win32")

        -- init flags for dlang
        local dc_archs = { x86 = "-m32", x64 = "-m64" }
        platform:add("dcflags", dc_archs[arch])
        platform:add("dc-shflags", dc_archs[arch])
        platform:add("dc-ldflags", dc_archs[arch])

        -- init flags for cuda
        local cu_archs = { x86 = "-m32 -Xcompiler -m32", x64 = "-m64 -Xcompiler -m64" }
        platform:add("cuflags", cu_archs[arch] or "")
        platform:add("cu-shflags", cu_archs[arch] or "")
        platform:add("cu-ldflags", cu_archs[arch] or "")
        local cuda_dir = config.get("cuda")
        if cuda_dir then
            platform:add("cuflags", "-I" .. os.args(path.join(cuda_dir, "include")))
            platform:add("cu-ldflags", "-L" .. os.args(path.join(cuda_dir, "lib")))
            platform:add("cu-shflags", "-L" .. os.args(path.join(cuda_dir, "lib")))
        end
    end)

    -- set menu
    set_menu {
                config = 
                {   
                    {category = "Visual Studio SDK Configuration"                                   }
                ,   {nil, "vs",         "kv", "auto", "The Microsoft Visual Studio"                 }
                ,   {nil, "vs_toolset", "kv", nil,    "The Microsoft Visual Studio Toolset Version"
                                                    , "  .e.g --vs_toolset=14.0"                    }
                ,   {nil, "vs_sdkver",  "kv", nil,    "The Windows SDK Version of Visual Studio"
                                                    , "  .e.g --vs_sdkver=10.0.15063.0"             }
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
                    {                                                                               }
                ,   {nil, "vs",         "kv", "auto", "The Microsoft Visual Studio"                 }
                ,   {nil, "cuda",       "kv", "auto", "The Cuda SDK Directory"                      }
                ,   {nil, "qt",         "kv", "auto", "The Qt SDK Directory"                        }
                ,   {nil, "wdk",        "kv", "auto", "The WDK Directory"                           }
                ,   {nil, "vcpkg",      "kv", "auto", "The Vcpkg Directory"                         }
                }
            }


