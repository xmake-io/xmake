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

language("msrc")
    add_rules("win.sdk.resource")
    set_sourcekinds {mrc = ".rc"}
    set_sourceflags {mrc = "mrcflags"}
    set_langkinds   {msrc = "mrc"}
    set_mixingkinds("mrc")

    on_load("load")

    set_nameflags {
        object = {
            "config.includedirs"
        ,   "target.defines"
        ,   "target.undefines"
        ,   "target.includedirs"
        ,   "toolchain.includedirs"
        ,   "toolchain.defines"
        ,   "toolchain.undefines"
        ,   "target.sysincludedirs"
        ,   "toolchain.sysincludedirs"
        }
    }

    set_menu {
                config =
                {
                    {category = "Cross Complation Configuration/Compiler Configuration"       }
                ,   {nil, "mrc",        "kv", nil,          "The Microsoft Resource Compiler" }

                ,   {category = "Cross Complation Configuration/Compiler Flags Configuration" }
                ,   {nil, "mrcflags",   "kv", nil,          "The Microsoft Resource Flags"    }

                ,   {category = "Cross Complation Configuration/Builti Flags Configuration"   }
                ,   {nil, "includedirs","kv", nil,          "The Include Search Directories"  }
                }
            }

