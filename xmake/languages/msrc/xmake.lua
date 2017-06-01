--!The Make-like Build Utility based on Lua
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
-- Copyright (C) 2015 - 2017, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        xmake.lua
--

-- define language
language("msrc")

    -- set source file kinds
    set_sourcekinds {mrc = ".rc"}

    -- set source file flags
    set_sourceflags {mrc = "mrcflags"}

    -- set mixing kinds
    set_mixingkinds("mrc")

    -- on load
    on_load("load")

    -- set name flags
    set_nameflags 
    {
        object =
        {
            "config.includedirs"
        ,   "target.defines"
        ,   "target.undefines"
        ,   "target.includedirs"
        ,   "option.defines"
        ,   "option.undefines"
        ,   "option.defines_if_ok"
        ,   "option.undefines_if_ok"
        ,   "platform.includedirs"
        ,   "platform.defines"
        ,   "platform.undefines"
        }
    }

    -- set menu
    set_menu {
                config = 
                {   
                    {                                                                         }
                ,   {nil, "mrc",        "kv", nil,          "The Microsoft Resource Compiler" }
                ,   {nil, "mrcflags",   "kv", nil,          "The Microsoft Resource Flags"    }

                ,   {                                                                         }
                ,   {nil, "includedirs","kv", nil,          "The Include Search Directories"  }
                }
            } 

