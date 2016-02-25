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
                    ,   {'j', "jobs",       "kv", nil,          "Specifies the number of jobs to build simultaneously"          }
                   
                    ,   {}
                    ,   {nil, "target",     "v",  "all",        "Build the given target."                                       } 
                    }
                })



