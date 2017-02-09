--!The Make-like Build Utility based on Lua
--
-- Licensed to the Apache Software Foundation (ASF) under one
-- or more contributor license agreements.  See the NOTICE file
-- distributed with this work for additional information
-- regarding copyright ownership.  The ASF licenses this file
-- to you under the Apache License, Version 2.0 (the
-- "License"); you may not use this file except in compliance
-- with the License.  You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- 
-- Copyright (C) 2015 - 2017, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        echo.lua
--

-- define task
task("echo")

    -- set category
    set_category("plugin")

    -- on run
    on_run(function ()

        -- imports
        import("core.base.option")

        -- init modes
        local modes = ""
        for _, mode in ipairs({"bright", "dim", "blink", "reverse"}) do
            if option.get(mode) then
                modes = modes .. " " .. mode 
            end
        end

        -- echo info
        cprint("${%s%s}%s", option.get("color"), modes, table.concat(option.get("contents") or {}, " "))
    end)

    -- set menu
    set_menu {
                -- usage
                usage = "xmake echo [options]"

                -- description
            ,   description = "Echo the given info!"

                -- options
            ,   options = 
                {
                    {'b', "bright",     "k",  nil,       "Enable bright."               }      
                ,   {'d', "dim",        "k",  nil,       "Enable dim."                  }      
                ,   {'-', "blink",      "k",  nil,       "Enable blink."                }      
                ,   {'r', "reverse",    "k",  nil,       "Reverse color."               }      
                ,   {}
                ,   {'c', "color",      "kv", "black",   "Set the output color."
                                                     ,   "    - red"   
                                                     ,   "    - blue"
                                                     ,   "    - yellow"
                                                     ,   "    - green"
                                                     ,   "    - magenta"
                                                     ,   "    - cyan" 
                                                     ,   "    - white"                  }
                ,   {}
                ,   {nil, "contents",   "vs", nil,       "The info contents."           }
                }
            } 
