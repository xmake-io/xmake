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

language("fortran")
    add_rules("fortran")
    set_sourcekinds {fc = {".f03", ".f90", ".f95", ".for", ".f"}}
    set_sourceflags {fc = "fcflags"}
    set_targetkinds {binary = "fcld", static = "ar", shared = "fcsh"}
    set_targetflags {binary = "ldflags", static = "arflags", shared = "shflags"}
    set_langkinds   {fortran = "fc"}
    set_mixingkinds("fc", "cc", "cxx", "as")

    on_load("load")
    on_check_main("check_main")

    set_nameflags {
        object = {
            "config.includedirs"
        ,   "target.symbols"
        ,   "target.warnings"
        ,   "target.optimize:check"
        ,   "target.vectorexts:check"
        ,   "target.includedirs"
        ,   "toolchain.includedirs"
        ,   "target.sysincludedirs"
        ,   "toolchain.sysincludedirs"
        }
    ,   binary = {
            "config.linkdirs"
        ,   "target.linkdirs"
        ,   "target.rpathdirs"
        ,   "target.strip"
        ,   "target.symbols"
        ,   "toolchain.linkdirs"
        ,   "toolchain.rpathdirs"
        ,   "config.links"
        ,   "target.links"
        ,   "toolchain.links"
        ,   "config.syslinks"
        ,   "target.syslinks"
        ,   "toolchain.syslinks"
        }
    ,   shared = {
            "config.linkdirs"
        ,   "target.linkdirs"
        ,   "target.strip"
        ,   "target.symbols"
        ,   "toolchain.linkdirs"
        ,   "config.links"
        ,   "target.links"
        ,   "toolchain.links"
        ,   "config.syslinks"
        ,   "target.syslinks"
        ,   "toolchain.syslinks"
        }
    ,   static = {
            "target.strip"
        ,   "target.symbols"
        }
    }

    set_menu {
                config =
                {
                    {category = "Cross Complation Configuration/Compiler Configuration"          }
                ,   {nil, "fc",         "kv", nil,          "The Fortran Compiler"               }

                ,   {category = "Cross Complation Configuration/Linker Configuration"            }
                ,   {nil, "fcld",       "kv", nil,          "The Fortran Linker"                 }
                ,   {nil, "fcsh",       "kv", nil,          "The Fortran Shared Library Linker"  }

                ,   {category = "Cross Complation Configuration/Builtin Flags Configuration"     }
                ,   {nil, "links",      "kv", nil,          "The Link Libraries"                 }
                ,   {nil, "syslinks",   "kv", nil,          "The System Link Libraries"          }
                ,   {nil, "linkdirs",   "kv", nil,          "The Link Search Directories"        }
                ,   {nil, "includedirs","kv", nil,          "The Include Search Directories"     }
                }
            }

