-- define task
task("clean")

    -- set category
    set_task_category("action")

    -- on run
    on_task_run("main")

    -- set menu
    set_task_menu({
                    -- usage
                    usage = "xmake clean|c [options] [target]"

                    -- description
                ,   description = "Remove all binary and temporary files."

                    -- xmake c
                ,   shortname = 'c'

                    -- options
                ,   options = 
                    {
                        {'a', "all",        "k",  nil,          "Clean all auto-generated files by xmake."                      }
                    
                    ,   {}
                    ,   {nil, "target",     "v",  "all",        "Clean for the given target."                                   }      
                    }
                })



