--!The Automatic Cross-platform Build Tool
-- 
-- XMake is free software; you can redistribute it and/or modify
-- it under the terms of the GNU Lesser General Public License as published by
-- the Free Software Foundation; either version 2.1 of the License, or
-- (at your option) any later version.
-- 
-- XMake is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU Lesser General Public License for more details.
-- 
-- You should have received a copy of the GNU Lesser General Public License
-- along with XMake; 
-- If not, see <a href="http://www.gnu.org/licenses/"> http://www.gnu.org/licenses/</a>
-- 
-- Copyright (C) 2015 - 2016, ruki All rights reserved.
--
-- @author      ruki
-- @file        xmake.lua
--

-- define task
task("create")

    -- set category
    set_task_category("action")

    -- on run
    on_task_run("main")

    -- set menu
    set_task_menu({
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
                })



