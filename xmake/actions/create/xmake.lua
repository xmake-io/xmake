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
-- Copyright (C) 2015-present, Xmake Open Source Community.
--
-- @author      ruki
-- @file        xmake.lua
--

task("create")
    set_category("action")
    on_run("main")
    set_menu {
        usage = "xmake create [options] [target]",
        description = "Create a new project.",
        options = {
            {'f', "force",      "k",   nil,         "Force to create project in a non-empty directory."},
            {nil, "list",       "k",   nil,         "List all templates for each language."
                                                  , "    e.g."
                                                  , "    - xmake create --list"
                                                  , "    - xmake create --list -l c++"},
            {'l', "language",   "kv", "c++",        "The project language",
                                                    values = function (complete, opt)
                                                        import("actions.create.template", {rootdir = os.programdir()})

                                                        local languages = template.languages()
                                                        if not complete or not opt.template then
                                                            return languages
                                                        end
                                                        return template.languages_for_template(opt.template)
                                                    end                                                             },
            {'t', "template",   "kv", "console",    "Select the project template id or name of the given language.",
                                                    "    Use `xmake create --list` to view all templates.",
                                                    values = function (complete, opt)
                                                        if complete then
                                                            import("actions.create.template", {rootdir = os.programdir()})
                                                            import("core.base.hashset")
                                                            local templates_set = hashset.new()
                                                            local languages = opt.language and {opt.language} or template.languages()
                                                            for _, l in ipairs(languages) do
                                                                for _, t in ipairs(template.templates(l)) do
                                                                    templates_set:insert(t)
                                                                end
                                                            end
                                                            local templates = templates_set:to_array()
                                                            table.sort(templates)
                                                            return templates
                                                        end
                                                    end},
            {},
            {nil, "target",     "v",  nil,          "Create the given target."
                                                  , "Uses the project name as target if not exists."}
        }
    }
