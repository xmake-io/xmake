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

-- define language
language("zig")

    -- set source file kinds
    set_sourcekinds {zc = ".zig"}

    -- set source file flags
    set_sourceflags {zc = "zcflags"}

    -- set target kinds
    set_targetkinds {binary = "zcld", static = "zcar", shared = "zcsh"}

    -- set target flags
    set_targetflags {binary = "ldflags", static = "arflags", shared = "shflags"}

    -- set language kinds
    set_langkinds {zig = "zc"}

    -- set mixing kinds
    set_mixingkinds("zc", "cc", "cxx", "as")

    -- add rules
    add_rules("zig")

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
        ,   "option.linkdirs"
        ,   "option.rpathdirs"
        ,   "toolchain.linkdirs"
        ,   "toolchain.rpathdirs"
        ,   "config.links"
        ,   "target.links"
        ,   "option.links"
        ,   "toolchain.links"
        ,   "config.syslinks"
        ,   "target.syslinks"
        ,   "option.syslinks"
        ,   "toolchain.syslinks"
        }
    ,   shared =
        {
            "config.linkdirs"
        ,   "target.linkdirs"
        ,   "target.strip"
        ,   "target.symbols"
        ,   "option.linkdirs"
        ,   "toolchain.linkdirs"
        ,   "config.links"
        ,   "target.links"
        ,   "option.links"
        ,   "toolchain.links"
        ,   "config.syslinks"
        ,   "target.syslinks"
        ,   "option.syslinks"
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
                ,   {nil, "zc",         "kv", nil,          "The Zig Compiler"                   }

                ,   {category = "Cross Complation Configuration/Linker Configuration"            }
                ,   {nil, "zcld",       "kv", nil,          "The Zig Linker"                     }
                ,   {nil, "zcar",       "kv", nil,          "The Zig Static Library Archiver"    }
                ,   {nil, "zcsh",       "kv", nil,          "The Zig Shared Library Linker"      }

                ,   {category = "Cross Complation Configuration/Builtin Flags Configuration"     }
                ,   {nil, "links",      "kv", nil,          "The Link Libraries"                 }
                ,   {nil, "syslinks",   "kv", nil,          "The System Link Libraries"          }
                ,   {nil, "linkdirs",   "kv", nil,          "The Link Search Directories"        }
                }
            }

