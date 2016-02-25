--!The Automatic Cross-platform Build Tool
-- 
-- XMake is free software; you can redistribute it and/or modify
-- it under the terms of the GNU Lesser General Public License as published by
-- the Free Software Foundation; either version 2.1 of the License, or
-- (at your option) any later version.
-- 
-- XMake is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU Lesser General Public License for more details.
-- 
-- You should have received a copy of the GNU Lesser General Public License
-- along with XMake; 
-- If not, see <a href="http://www.gnu.org/licenses/"> http://www.gnu.org/licenses/</a>
-- 
-- Copyright (C) 2015 - 2016, ruki All rights reserved.
--
-- @author      ruki
-- @file        package.lua
--

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



