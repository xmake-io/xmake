-- define task
task("install")

    -- set category
    set_task_category("action")

    -- set menu
    set_task_menu({
                    -- usage
                    usage = "xmake install|i [options] [target]"

                    -- description
                ,   description = "Package and install the project binary files."

                    -- xmake i
                ,   shortname = 'i'

                    -- options
                ,   options = 
                    {
                        {'f', "file",       "kv", "xmake.lua",  "Read a given xmake.lua file."                                  }
                    ,   {'P', "project",    "kv", nil,          "Change to the given project directory."
                                                              , "Search priority:"
                                                              , "    1. The Given Command Argument"
                                                              , "    2. The Envirnoment Variable: XMAKE_PROJECT_DIR"
                                                              , "    3. The Current Directory"                                  }
                    ,   {'o', "installdir",  "kv", nil,         "Set the install directory."                                    }

                    ,   {}
                    ,   {nil, "target",     "v",  "all",        "Install the given target."                                     }
                    }
                })



