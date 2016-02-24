-- define task
task("uninstall")

    -- set category
    set_task_category("action")

    -- set menu
    set_task_menu({
                    -- usage
                    usage = "xmake uninstall|u [options] [target]"

                    -- description
                ,   description = "Uninstall the project binary files."

                    -- xmake u
                ,   shortname = 'u'

                    -- options
                ,   options = 
                    {
                        {'f', "file",       "kv", "xmake.lua",  "Read a given xmake.lua file."                                  }
                    ,   {'P', "project",    "kv", nil,          "Change to the given project directory."
                                                              , "Search priority:"
                                                              , "    1. The Given Command Argument"
                                                              , "    2. The Envirnoment Variable: XMAKE_PROJECT_DIR"
                                                              , "    3. The Current Directory"                                  }

                    ,   {}
                    ,   {nil, "target",     "v",  "all",        "Install the given target."                                     }
                    }
                })



