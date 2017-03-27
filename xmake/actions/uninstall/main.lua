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
-- @file        main.lua
--

-- imports
import("core.base.option")
import("core.project.task")
import("uninstall")

-- main
function main()

    -- get the target name
    local targetname = option.get("target")

    -- config it first
    task.run("config", {target = targetname})

    -- attempt to uninstall directly
    try
    {
        function ()
            -- uninstall target
            install.uninstall(targetname)
        end,

        catch
        {
            -- failed or not permission? request administrator permission and uninstall it again
            function (errors)

                -- init argv
                local argv = {"xmake", "lua"}
                for _, name in ipairs({"file", "project", "backtrace", "verbose", "quiet"}) do
                    local value = option.get(name)
                    if type(value) == "string" then
                        table.insert(argv, "--" .. name .. "=" .. value)
                    elseif value then
                        table.insert(argv, "--" .. name)
                    end
                end
                table.insert(argv, path.join(os.scriptdir(), "uninstall_admin.lua"))
                table.insert(argv, targetname)
                table.insert(argv, option.get("installdir"))

                -- show tips
                cprint("${bright red}error: ${default red}failed to uninstall, may permission denied!")

                -- continue to install with administrator permission?
                if os.sudo() then

                    -- show tips
                    cprint("${bright yellow}note: ${default yellow}try continue to uninstall with administrator permission again?")
                    cprint("please input: y (y/n)")

                    -- get answer
                    io.flush()
                    if io.read() == 'y' then

                        -- install target with administrator permission
                        os.runv(os.sudo(), argv)
                    end
                end
            end
        }
    }
end
