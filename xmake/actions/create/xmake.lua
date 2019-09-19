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
-- Copyright (C) 2015 - 2019, TBOOX Open Source Group.
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
                    {'l', "language",   "kv", "c++",        "The project language"

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
                ,   {'t', "template",   "kv", "console",    "Select the project template id or name of the given language."

                                                            -- show the description of all templates
                                                          , function ()

                                                                -- import template
                                                                import("core.project.template")

                                                                -- get templates
                                                                local templates = {}
                                                                for _, l in ipairs(template.languages()) do
                                                                    for _, t in ipairs(template.templates(l)) do
                                                                        templates[t:name()] = templates[t:name()] or {}
                                                                        table.insert(templates[t:name()], l)
                                                                    end
                                                                end

                                                                -- get sorted templates
                                                                local templates_sorted = {}
                                                                for name, languages in pairs(templates) do
                                                                    table.insert(templates_sorted, {name = name, languages = languages})
                                                                end
                                                                table.sort(templates_sorted, function(a, b) return a.name < b.name end)

                                                                -- make description
                                                                local description = {}
                                                                for _, t in ipairs(templates_sorted) do
                                                                    table.insert(description, "    - " .. t.name .. ": " .. table.concat(t.languages, ", "))
                                                                end
                                                                return description
                                                            end                                                             }

                ,   {}
                ,   {nil, "target",     "v",  nil,          "Create the given target."                     
                                                          , "Uses the project name as target if not exists."                }
                }
            }



