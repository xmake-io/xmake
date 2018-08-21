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
    on_load(function ()

        -- imports
        import("core.project.config")

        -- init flags for architecture
        local arch = config.get("arch") or os.arch()

        -- init flags for asm
        local as = config.get("as")
        if as and as:find("yasm", 1, true) then
            _g.asflags = { "-f", arch == "x64" and "win64" or "win32" }
        end

        -- init flags for dlang
        local dc_archs = { x86 = "-m32", x64 = "-m64" }
        _g.dcflags       = { dc_archs[arch] }
        _g["dc-shflags"] = { dc_archs[arch] }
        _g["dc-ldflags"] = { dc_archs[arch] }

        -- init flags for cuda
        local cu_archs = { x86 = "-m32 -Xcompiler -m32", x64 = "-m64 -Xcompiler -m64" }
        _g.cuflags = {cu_archs[arch] or ""}
        _g["cu-shflags"] = {cu_archs[arch] or ""}
        _g["cu-ldflags"] = {cu_archs[arch] or ""}
        local cuda_dir = config.get("cuda")
        if cuda_dir then
            table.insert(_g.cuflags, "-I" .. os.args(path.join(cuda_dir, "include")))
            table.insert(_g["cu-ldflags"], "-L" .. os.args(path.join(cuda_dir, "lib")))
            table.insert(_g["cu-shflags"], "-L" .. os.args(path.join(cuda_dir, "lib")))
        end

        -- ok
        return _g
    end)

    -- set menu
    set_menu {
                config = 
                {   
                    {category = "Visual Studio SDK Configuration"                  }
                ,   {nil, "vs",        "kv", "auto", "The Microsoft Visual Studio" }
                ,   {category = "Cuda SDK Configuration"                           }
                ,   {nil, "cuda",      "kv", "auto", "The Cuda SDK Directory"      }
                ,   {category = "Qt SDK Configuration"                             }
                ,   {nil, "qt",        "kv", "auto", "The Qt SDK Directory"        }
                ,   {nil, "qt_sdkver", "kv", "auto", "The Qt SDK Version"          }
                ,   {category = "WDK Configuration"                                }
                ,   {nil, "wdk",       "kv", "auto", "The WDK Directory"           }
                ,   {nil, "wdk_sdkver","kv", "auto", "The WDK Version"             }
                ,   {nil, "wdk_winver","kv", "auto", "The WDK Windows Version",
                                                     "  - win10_rs3",
                                                     "  - win10",
                                                     "  - win81",
                                                     "  - win8",
                                                     "  - win7",
                                                     "  - win7_[sp1|sp2|sp3]"      }
                ,   {category = "Vcpkg Configuration"                              }
                ,   {nil, "vcpkg",     "kv", "auto", "The Vcpkg Directory"         }
                }

            ,   global = 
                {   
                    {                                                              }
                ,   {nil, "vs",        "kv", "auto", "The Microsoft Visual Studio" }
                ,   {nil, "cuda",      "kv", "auto", "The Cuda SDK Directory"      }
                ,   {nil, "qt",        "kv", "auto", "The Qt SDK Directory"        }
                ,   {nil, "wdk",       "kv", "auto", "The WDK Directory"           }
                ,   {nil, "vcpkg",     "kv", "auto", "The Vcpkg Directory"         }
                }
            }


