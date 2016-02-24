-- define task
task("lua")

    -- set category
    set_task_category("action")

    -- set menu
    set_task_menu({
                    -- usage
                    usage = "xmake lua|l [options] [script] [arguments]"

                    -- description
                ,   description = "Run the lua script."

                    -- xmake l
                ,   shortname = 'l'

                    -- options
                ,   options = 
                    {
                        {'f', "file",       "kv", nil,          "Read a given xmake.lua file."                                  }
                    ,   {'P', "project",    "kv", nil,          "Change to the given project directory."
                                                              , "Search priority:"
                                                              , "    1. The Given Command Argument"
                                                              , "    2. The Envirnoment Variable: XMAKE_PROJECT_DIR"
                                                              , "    3. The Current Directory"                                  }

                    ,   {}
                    ,   {'s', "string",     "k",  nil,          "Run the lua string script."                                    }

                    ,   {}
                    ,   {'v', "verbose",    "k",  nil,          "Print lots of verbose information."                            }
                    ,   {nil, "version",    "k",  nil,          "Print the version number and exit."                            }
                    ,   {'h', "help",       "k",  nil,          "Print this help message and exit."                             }
                    
                    ,   {}
                    ,   {nil, "script",     "v",  nil,          "Run the given lua script."
                                                              , "    - The script name from the xmake tool directory"
                                                              , "    - The script file"
                                                              , "    - The script string"                                       }      
                    ,   {nil, "arguments",  "vs", nil,          "The script arguments"                                          }
                    }
                })



