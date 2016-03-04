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
                        {'a', "archs",      "kv", nil,          "Package multiple given architectures."                             
                                                              , "    .e.g --archs=\"armv7, arm64\" or -a i386"
                                                              , ""
                                                                -- show the description of all architectures
                                                              , function () 

                                                                    -- import platform menu
                                                                    import("core.platform.menu")

                                                                    -- make description
                                                                    local description = {}
                                                                    for i, plat in ipairs(menu.plats()) do
                                                                        description[i] = "    - " .. plat .. ":"
                                                                        for _, arch in ipairs(menu.archs(plat)) do
                                                                            description[i] = description[i] .. " " .. arch
                                                                        end
                                                                    end

                                                                    -- get it
                                                                    return description
                                                                end                                                             }

                    ,   {'o', "outputdir",  "kv", nil,          "Set the output directory."                                     }

                    ,   {}
                    ,   {nil, "target",     "v",  "all",        "Package a given target"                                        }   
                    }
                })



