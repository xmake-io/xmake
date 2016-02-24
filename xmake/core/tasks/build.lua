-- define task
task("build")

    -- set category
    set_task_category("main")

    -- set menu
    set_task_menu({
                    -- usage
                    usage = "xmake [task] [options] [target]"

                    -- description
                ,   description = "Build the project if no given tasks."

                    -- options
                ,   options = 
                    {
                        {'b', "build",      "k",  nil,          "Build project. This is default building mode and optional."    }
                    ,   {'u', "update",     "k",  nil,          "Only relink and update the binary files."                      }
                    ,   {'r', "rebuild",    "k",  nil,          "Rebuild the project."                                          }

                    ,   {}
                    ,   {'f', "file",       "kv", "xmake.lua",  "Read a given xmake.lua file."                                  }
                    ,   {'P', "project",    "kv", nil,          "Change to the given project directory."
                                                              , "Search priority:"
                                                              , "    1. The Given Command Argument"
                                                              , "    2. The Envirnoment Variable: XMAKE_PROJECT_DIR"
                                                              , "    3. The Current Directory"                                  }


                    ,   {}
                    ,   {'j', "jobs",       "kv", nil,          "Specifies the number of jobs to build simultaneously"          }
                   
                    ,   {}
                    ,   {nil, "target",     "v",  "all",        "Build the given target."                                       } 
                    }
                })



