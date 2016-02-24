-- define task
task("global")

    -- set category
    set_task_category("action")

    -- set menu
    set_task_menu({
                    -- usage
                    usage = "xmake global|g [options] [target]"

                    -- description
                ,   description = "Configure the global options for xmake."

                    -- xmake g
                ,   shortname = 'g'

                    -- options
                ,   options = 
                    {
                        {'c', "clean",      "k",    nil,            "Clean the cached configure and configure all again."       }
                    ,   {nil, "make",       "kv",   "auto",         "Set the make path."                                        }
                    ,   {nil, "ccache",     "kv",   "auto",         "Enable or disable the c/c++ compiler cache." 
                                                                 ,  "    --ccache=[y|n]"                                        }

                    ,   {}
                        -- the options for all platforms
--                    ,   function () return platform.menu("global") end

                    }
                })



