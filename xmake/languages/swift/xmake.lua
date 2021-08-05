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

language("swift")
    add_rules("swift")
    set_sourcekinds {sc = ".swift"}
    set_sourceflags {sc = "scflags"}
    set_targetkinds {binary = "scld", static = "ar", shared = "scsh"}
    set_targetflags {binary = "ldflags", static = "arflags", shared = "shflags"}
    set_langkinds   {swift = "sc"}
    set_mixingkinds("sc", "mm", "mxx", "cc", "cxx")

    on_load("load")

    set_nameflags {
        object = {
            "config.includedirs"
        ,   "config.frameworkdirs"
        ,   "config.Frameworks"
        ,   "target.symbols"
        ,   "target.warnings"
        ,   "target.optimize:check"
        ,   "target.vectorexts:check"
        ,   "target.languages"
        ,   "target.includedirs"
        ,   "target.defines"
        ,   "target.undefines"
        ,   "target.frameworkdirs"
        ,   "target.frameworks"
        ,   "toolchain.includedirs"
        ,   "toolchain.defines"
        ,   "toolchain.undefines"
        ,   "toolchain.frameworkdirs"
        ,   "toolchain.frameworks"
        }
    ,   binary = {
            "config.linkdirs"
        ,   "config.frameworkdirs"
        ,   "target.linkdirs"
        ,   "target.rpathdirs"
        ,   "target.frameworkdirs"
        ,   "target.strip"
        ,   "target.symbols"
        ,   "toolchain.linkdirs"
        ,   "toolchain.rpathdirs"
        ,   "toolchain.frameworkdirs"
        ,   "config.links"
        ,   "target.links"
        ,   "toolchain.links"
        ,   "config.frameworks"
        ,   "target.frameworks"
        ,   "toolchain.frameworks"
        ,   "config.syslinks"
        ,   "target.syslinks"
        ,   "toolchain.syslinks"
        }
    ,   shared = {
            "config.linkdirs"
        ,   "config.frameworkdirs"
        ,   "target.linkdirs"
        ,   "target.frameworkdirs"
        ,   "target.strip"
        ,   "target.symbols"
        ,   "toolchain.linkdirs"
        ,   "toolchain.frameworkdirs"
        ,   "config.links"
        ,   "target.links"
        ,   "toolchain.links"
        ,   "config.frameworks"
        ,   "target.frameworks"
        ,   "toolchain.frameworks"
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
                    {category = "Cross Complation Configuration/Compiler Configuration"                              }
                ,   { nil, "sc",            "kv", nil,          "The Swift Compiler"                                 }

                ,   {category = "Cross Complation Configuration/Linker Configuration"                                }
                ,   { nil, "scld",         "kv", nil,          "The Swift Linker"                                   }
                ,   { nil, "scsh",         "kv", nil,          "The Swift Shared Library Linker"                    }

                ,   { category = "Cross Complation Configuration/Builtin Flags Configuration"                        }
                ,   { nil, "links",         "kv", nil,          "The Link Libraries"                                 }
                ,   { nil, "syslinks",      "kv", nil,          "The System Link Libraries"                          }
                ,   { nil, "linkdirs",      "kv", nil,          "The Link Search Directories"                        }
                ,   { nil, "includedirs",   "kv", nil,          "The Include Search Directories"                     }
                ,   { nil, "frameworks",    "kv", nil,          "The Frameworks"                                     }
                ,   { nil, "frameworkdirs", "kv", nil,          "The Frameworks Search Directories"                  }
                }
            }




