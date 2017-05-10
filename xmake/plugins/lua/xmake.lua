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
-- @file        xmake.lua
--

-- define task
task("lua")

    -- set category
    set_category("plugin")

    -- on run
    on_run(function ()
           
        -- imports
        import("core.base.option")
        import("core.sandbox.sandbox")

        -- list all scripts?
        if option.get("list") then
            print("scripts:")
            local files = os.match(path.join(os.scriptdir(), "scripts/*.lua"))
            for _, file in ipairs(files) do
                print("    " .. path.basename(file))
            end
            return 
        end

        -- get script name
        local name = option.get("script")
        if name then

            -- import and run script
            if os.isfile(name) then
                import(path.basename(name), {rootdir = path.directory(name)}).main(unpack(option.get("arguments") or {}))
            else
                import("scripts." .. name).main(unpack(option.get("arguments") or {}))
            end
        else
            -- enter interactive mode
            sandbox.interactive()
        end
    end)

    -- set menu
    set_menu {
                -- usage
                usage = "xmake lua|l [options] [script] [arguments]"

                -- description
            ,   description = "Run the lua script."

                -- xmake l
            ,   shortname = 'l'

                -- options
            ,   options = 
                {
                    {'l', "list",       "k",  nil,          "List all scripts."             }      
                ,   {nil, "root",       "k",  nil,          "Allow to run script as root."  }      
                ,   {nil, "script",     "v",  nil,          "Run the given lua script."     }      
                ,   {nil, "arguments",  "vs", nil,          "The script arguments."         }
                }
            }



