-- define task
task("create")

    -- set category
    set_task_category("action")

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
                    ,   {'f', "file",       "kv", "xmake.lua",  "Create a given xmake.lua file."                                }
                    ,   {'P', "project",    "kv", nil,          "Create from the given project directory."
                                                              , "Search priority:"
                                                              , "    1. The Given Command Argument"
                                                              , "    2. The Envirnoment Variable: XMAKE_PROJECT_DIR"
                                                              , "    3. The Current Directory"                                  }
--[[                    ,   {'l', "language",   "kv", "c",          "The project language"
                                                              , function ()
                                                                    local descriptions = {}
                                                                    local languages = template.languages()
                                                                    for _, language in ipairs(languages) do
                                                                        table.insert(descriptions, "    - " .. language)
                                                                    end
                                                                    return descriptions
                                                                end                                                             }
                    ,   {'t', "template",   "kv", "1",          "Select the project template id of the given language."
                                                              , function ()
                                                                    local descriptions = {}
                                                                    local languages = template.languages()
                                                                    for _, language in ipairs(languages) do
                                                                        table.insert(descriptions, string.format("    - language: %s", language))
                                                                        local templates = template.loadall(language)
                                                                        if templates then
                                                                            for i, template in ipairs(templates) do
                                                                                table.insert(descriptions, string.format("      %d. %s", i, utils.ifelse(template.description, template.description, "The Unknown Project")))
                                                                            end
                                                                        end
                                                                    end
                                                                    return descriptions
                                                                end                                                             }

                    ,   {}]]
                    ,   {}
                    ,   {nil, "target",     "v",  nil,          "Create the given target."                     
                                                              , "Uses the project name as target if not exists."                }
                    }
                })



