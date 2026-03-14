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
-- @author      JassJam
-- @file        xmake.lua
--

language("csharp")
    add_rules("csharp")
    set_sourcekinds {cs = ".cs"}
    set_sourceflags {cs = "csflags"}
    set_targetkinds {binary = "cs", shared = "cs"}
    set_targetflags {binary = "ldflags", shared = "shflags"}
    set_langkinds {csharp = "cs"}
    set_mixingkinds("cs")

    on_load("load")

    set_nameflags {
        object = {
            "target.symbols"
        ,   "target.warnings"
        ,   "target.optimize:check"
        }
    ,   binary = {
            "config.linkdirs"
        ,   "target.linkdirs"
        ,   "config.links"
        ,   "target.links"
        ,   "config.syslinks"
        ,   "target.syslinks"
        }
    ,   shared = {
            "config.linkdirs"
        ,   "target.linkdirs"
        ,   "config.links"
        ,   "target.links"
        ,   "config.syslinks"
        ,   "target.syslinks"
        }
    }

    set_menu {
                config =
                {
                    {category = "Cross Complation Configuration/Compiler Configuration"       }
                ,   {nil, "cs",         "kv", nil,          "The C# Compiler"                 }

                ,   {category = "Cross Complation Configuration/Linker Configuration"         }
                ,   {nil, "ld",         "kv", nil,          "The Linker"                      }
                ,   {nil, "sh",         "kv", nil,          "The Shared Library Linker"       }

                ,   {category = "Cross Complation Configuration/Compiler Flags Configuration" }
                ,   {nil, "csflags",    "kv", nil,          "The C# Compiler Flags"           }

                ,   {category = "Cross Complation Configuration/Linker Flags Configuration"   }
                ,   {nil, "ldflags",    "kv", nil,          "The Binary Linker Flags"         }
                ,   {nil, "shflags",    "kv", nil,          "The Shared Library Linker Flags" }
                }
            }

