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

language("asm")
    add_rules("asm")
    set_sourcekinds {as = {".s", ".asm"}}
    set_sourceflags {as = "asflags"}
    set_targetkinds {binary = "ld", static = "ar", shared = "sh"}
    set_targetflags {binary = "ldflags", static = "arflags", shared = "shflags"}
    set_langkinds   {as = "as"}
    set_mixingkinds("as")

    on_load("load")

    set_nameflags {
        object = {
            "config.includedirs"
        ,   "target.symbols"
        ,   "target.warnings"
        ,   "target.optimize:check"
        ,   "target.vectorexts:check"
        ,   "target.languages"
        ,   "target.includedirs"
        ,   "target.defines"
        ,   "target.undefines"
        ,   "target.runtimes"
        ,   "toolchain.includedirs"
        ,   "toolchain.defines"
        ,   "toolchain.undefines"
        ,   "target.sysincludedirs"
        ,   "toolchain.sysincludedirs"
        }
    ,   binary = {
            "config.linkdirs"
        ,   "target.linkdirs"
        ,   "target.rpathdirs"
        ,   "target.strip"
        ,   "target.symbols"
        ,   "target.runtimes"
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
        ,   "target.runtimes"
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
                    {category = "Cross Complation Configuration/Compiler Configuration"       }
                ,   {nil, "as",         "kv", nil,          "The Assembler"                   }

                ,   {category = "Cross Complation Configuration/Linker Configuration"         }
                ,   {nil, "ar",         "kv", nil,          "The Static Library Linker"       }
                ,   {nil, "ld",         "kv", nil,          "The Linker"                      }
                ,   {nil, "sh",         "kv", nil,          "The Shared Library Linker"       }

                ,   {category = "Cross Complation Configuration/Compiler Flags Configuration" }
                ,   {nil, "asflags",    "kv", nil,          "The Assembler Flags"             }

                ,   {category = "Cross Complation Configuration/Linker Flags Configuration"   }
                ,   {nil, "ldflags",    "kv", nil,          "The Binary Linker Flags"         }
                ,   {nil, "arflags",    "kv", nil,          "The Static Library Linker Flags" }
                ,   {nil, "shflags",    "kv", nil,          "The Shared Library Linker Flags" }

                ,   {category = "Cross Complation Configuration/Builin Flags Configuration"   }
                ,   {nil, "links",      "kv", nil,          "The Link Libraries"              }
                ,   {nil, "syslinks",   "kv", nil,          "The System Link Libraries"       }
                ,   {nil, "linkdirs",   "kv", nil,          "The Link Search Directories"     }
                ,   {nil, "includedirs","kv", nil,          "The Include Search Directories"  }
                }
            }








