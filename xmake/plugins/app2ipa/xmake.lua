--!The Make-like Build Utility based on Lua
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
-- @file        app2ipa.lua
--

-- define task
task("app2ipa")

    -- set category
    set_category("plugin")

    -- on run
    on_run("main")

    -- set menu
    set_menu({
                    -- usage
                    usage = "xmake app2ipa [options] xxx.app"

                    -- description
                ,   description = "Generate .ipa file from the given .app"

                    -- options
                ,   options = 
                    {
                        {'o', "ipa",  "kv", nil,    "Set the .ipa file path."    }
                    ,   {nil, "icon", "kv", nil,    "Set the icon file path."    }
                    ,   {}
                    ,   {nil, "app",  "v",  nil,    "Set the .app directory."    }
                    }
                }) 
