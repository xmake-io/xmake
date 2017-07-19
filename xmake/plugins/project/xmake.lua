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

-- define task
task("project")

    -- set category
    set_category("plugin")

    -- on run
    on_run("main")

    -- set menu
    set_menu {
                -- usage
                usage = "xmake project [options] [target]"

                -- description
            ,   description = "Generate the project file."

                -- options
            ,   options = 
                {
                    {'k', "kind",      "kv", "makefile",    "Set the project kind." 
                                                       ,    "    - makefile"
                                                       ,    "    - compile_commands (clang compilation database with json format)"
                                                       ,    "    - vs2002, vs2003, vs2005, vs2008, vs2010, vs2012, vs2013, vs2015, vs2017" }
                ,   {'m', "modes",     "kv", nil,           "Set the project modes." 
                                                       ,    "    .e.g "
                                                       ,    "    - xmake project -k makefile"
                                                       ,    "    - xmake project -k compile_commands"
                                                       ,    "    - xmake project -k vs2015 -m \"release,debug\"" }
                ,   {nil, "outputdir", "v",  ".",           "Set the output directory." }
                }
            }



