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

language("rust")
    add_rules("rust")
    set_sourcekinds {rc = ".rs"}
    set_sourceflags {rc = "rcflags"}
    set_targetkinds {binary = "rcld", static = "rcar", shared = "rcsh"}
    set_targetflags {binary = "ldflags", static = "arflags", shared = "shflags"}
    set_langkinds {rust = "rc"}
    set_mixingkinds("rc", "cc", "cxx")

    on_load("load")
    on_check_main("check_main")

    set_nameflags {
        object = {
            "target.symbols"
        ,   "target.warnings"
        ,   "target.optimize:check"
        ,   "target.vectorexts:check"
        }
    ,   binary = {
            "config.linkdirs"
        ,   "config.frameworkdirs"
        ,   "target.linkdirs"
        ,   "target.frameworkdirs"
        ,   "target.rpathdirs"
        ,   "target.strip"
        ,   "target.symbols"
        ,   "toolchain.linkdirs"
        ,   "toolchain.frameworkdirs"
        ,   "toolchain.rpathdirs"
        ,   "config.frameworks"
        ,   "target.frameworks"
        ,   "toolchain.frameworks"
        ,   "config.links"
        ,   "target.links"
        ,   "toolchain.links"
        ,   "config.syslinks"
        ,   "target.syslinks"
        ,   "toolchain.syslinks"
        }
    ,   shared = {
            "config.linkdirs"
        ,   "config.frameworkdirs"
        ,   "target.linkdirs"
        ,   "target.frameworkdirs"
        ,   "target.rpathdirs"
        ,   "target.strip"
        ,   "target.symbols"
        ,   "toolchain.linkdirs"
        ,   "toolchain.frameworkdirs"
        ,   "toolchain.rpathdirs"
        ,   "config.frameworks"
        ,   "target.frameworks"
        ,   "toolchain.frameworks"
        ,   "config.links"
        ,   "target.links"
        ,   "toolchain.links"
        ,   "config.syslinks"
        ,   "target.syslinks"
        ,   "toolchain.syslinks"
        }
    ,   static = {
            "config.linkdirs"
        ,   "config.frameworkdirs"
        ,   "target.linkdirs"
        ,   "target.frameworkdirs"
        ,   "target.strip"
        ,   "target.symbols"
        ,   "toolchain.linkdirs"
        ,   "toolchain.frameworkdirs"
        ,   "config.frameworks"
        ,   "target.frameworks"
        ,   "toolchain.frameworks"
        }
    }

    set_menu {
                config =
                {
                    {category = "Cross Complation Configuration/Compiler Configuration"        }
                ,   {nil, "rc",         "kv", nil,          "The Rust Compiler"                }

                ,   {category = "Cross Complation Configuration/Linker Configuration"          }
                ,   {nil, "rcld",      "kv", nil,          "The Rust Linker"                  }
                ,   {nil, "rcar",      "kv", nil,          "The Rust Static Library Archiver" }
                ,   {nil, "rcsh",      "kv", nil,          "The Rust Shared Library Linker"   }

                ,   {category = "Cross Complation Configuration/Builtin Flags Configuration"   }
                ,   {nil, "linkdirs",   "kv", nil,          "The Link Search Directories"      }
                }
            }

