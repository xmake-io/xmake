-- define task
task("run")

    -- set category
    set_task_category("action")

    -- set menu
    set_task_menu({
                    -- usage
                    usage = "xmake run|r [options] [target] [arguments]"

                    -- description
                ,   description = "Run the project target."

                    -- xmake r
                ,   shortname = 'r'
 
                    -- options
                ,   options = 
                    {
                        {'d', "debug",      "k",  nil,          "Run and debug the given target."                               }
                    ,   {nil, "debugger",   "kv", "auto",       "Set the debugger path."                                        }

                    ,   {}
                    ,   {'f', "file",       "kv", "xmake.lua",  "Read a given xmake.lua file."                                  }
                    ,   {'P', "project",    "kv", nil,          "Change to the given project directory."
                                                              , "Search priority:"
                                                              , "    1. The Given Command Argument"
                                                              , "    2. The Envirnoment Variable: XMAKE_PROJECT_DIR"
                                                              , "    3. The Current Directory"                                  }
                    ,   {}
                    ,   {nil, "target",     "v",  nil,          "Run the given target."                                         }      
                    ,   {nil, "arguments",  "vs",  nil,         "The target arguments"                                          }
                    }
                })



