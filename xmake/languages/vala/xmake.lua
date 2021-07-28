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

-- define language
language("vala")

    -- set source file kinds
    set_sourcekinds {va = ".vala"}

    -- set source file flags
    set_sourceflags {va = "vaflags"}

    -- set target kinds
    set_targetkinds {binary = "vald", static = "vaar", shared = "vash"}

    -- set target flags
    set_targetflags {binary = "ldflags", static = "arflags", shared = "shflags"}

    -- set language kinds
    set_langkinds {vala = "va"}

    -- set mixing kinds
    set_mixingkinds("va", "cc", "cxx", "as")

    -- add rules
    add_rules("vala")

    -- on load
    on_load("load")

    -- on check_main
    on_check_main("check_main")

    -- set name flags
    set_nameflags
    {
        object =
        {
            "target.symbols"
        ,   "target.warnings"
        ,   "target.optimize:check"
        ,   "target.vectorexts:check"
        }
    ,   binary =
        {
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
    ,   shared =
        {
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
    ,   static =
        {
            "target.strip"
        ,   "target.symbols"
        }
    }

    -- set menu
    set_menu {
                config =
                {
                    {category = "Cross Complation Configuration/Compiler Configuration"          }
                ,   {nil, "va",         "kv", nil,          "The Vala Compiler"                   }

                ,   {category = "Cross Complation Configuration/Linker Configuration"            }
                ,   {nil, "vald",       "kv", nil,          "The Vala Linker"                     }
                ,   {nil, "vaar",       "kv", nil,          "The Vala Static Library Archiver"    }
                ,   {nil, "vash",       "kv", nil,          "The Vala Shared Library Linker"      }

                ,   {category = "Cross Complation Configuration/Builtin Flags Configuration"     }
                ,   {nil, "links",      "kv", nil,          "The Link Libraries"                 }
                ,   {nil, "syslinks",   "kv", nil,          "The System Link Libraries"          }
                ,   {nil, "linkdirs",   "kv", nil,          "The Link Search Directories"        }
                }
            }

