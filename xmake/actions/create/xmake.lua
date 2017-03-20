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
task("create")

    -- set category
    set_category("action")

    -- on run
    on_run("main")

    -- set menu
    set_menu {
                -- usage
                usage = "xmake create [options] [target]"

                -- description
            ,   description = "Create a new project."

                -- options
            ,   options = 
                {
                    {'n', "name",       "kv", nil,          "The project name."                                             }
                ,   {'l', "language",   "kv", "c",          "The project language"

                                                            -- show the description of all languages
                                                          , function ()

                                                                -- import template
                                                                import("core.project.template")

                                                                -- make description
                                                                local description = {}
                                                                for _, language in ipairs(template.languages()) do
                                                                    table.insert(description, "    - " .. language)
                                                                end

                                                                -- get it
                                                                return description
                                                            end                                                             }
                ,   {'t', "template",   "kv", "1",          "Select the project template id of the given language."

                                                            -- show the description of all templates
                                                          , function ()

                                                                -- import template
                                                                import("core.project.template")

                                                                -- make description
                                                                local description = {}
                                                                for _, language in ipairs(template.languages()) do
                                                                    table.insert(description, format("    - language: %s", language))
                                                                    for i, t in ipairs(template.templates(language)) do
                                                                        table.insert(description, format("      %d. %s", i, ifelse(t.description, t.description, "The Unknown Project")))
                                                                    end
                                                                end

                                                                -- get it
                                                                return description
                                                            end                                                             }

                ,   {}
                ,   {nil, "target",     "v",  nil,          "Create the given target."                     
                                                          , "Uses the project name as target if not exists."                }
                }
            }



