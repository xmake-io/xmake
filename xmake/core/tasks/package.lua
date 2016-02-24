-- define task
task("package")

    -- set category
    set_task_category("action")

    -- set menu
    set_task_menu({
                    -- usage
                    usage = "xmake package|p [options] [target]"

                    -- description
                ,   description = "Package target."

                    -- xmake p
                ,   shortname = 'p'

                    -- options
                ,   options = 
                    {
--[[                        {'a', "archs",      "kv", nil,          "Package multiple given architectures."                             
                                                              , "    .e.g --archs=\"armv7, arm64\" or -a i386"
                                                              , ""
                                                              , function () 
                                                                  local descriptions = {}
                                                                  local plats = platform.plats()
                                                                  if plats then
                                                                      for i, plat in ipairs(plats) do
                                                                          descriptions[i] = "    - " .. plat .. ":"
                                                                          local archs = platform.archs(plat)
                                                                          if archs then
                                                                              for _, arch in ipairs(archs) do
                                                                                  descriptions[i] = descriptions[i] .. " " .. arch
                                                                              end
                                                                          end
                                                                      end
                                                                  end
                                                                  return descriptions
                                                                end                                                             }]]

                    ,   {}
                    ,   {'f', "file",       "kv", "xmake.lua",  "Create a given xmake.lua file."                                }
                    ,   {'P', "project",    "kv", nil,          "Create from the given project directory."
                                                              , "Search priority:"
                                                              , "    1. The Given Command Argument"
                                                              , "    2. The Envirnoment Variable: XMAKE_PROJECT_DIR"
                                                              , "    3. The Current Directory"                                  }
                    ,   {'o', "outputdir",  "kv", nil,          "Set the output directory."                                     }

                    ,   {}
                    ,   {nil, "target",     "v",  "all",        "Package a given target"                                        }   
                    }
                })



