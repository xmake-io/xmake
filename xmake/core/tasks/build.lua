-- define task
task("build")

    -- set category
    set_task_category("main")

    -- set menu
    set_task_menu({
                    -- usage
                    usage = "xmake [action] [options] [target]"

                    -- description
                ,   description = "Build the project if no given action."

                    -- actions
 --               ,   actions = function () return task.menu(true) end

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
                    ,   {'v', "verbose",    "k",  nil,          "Print lots of verbose information."                            }
                    ,   {nil, "version",    "k",  nil,          "Print the version number and exit."                            }
                    ,   {'h', "help",       "k",  nil,          "Print this help message and exit."                             }

                    ,   {}
                    ,   {nil, "target",     "v",  "all",        "Build the given target."                                       } 
                    }
                })



