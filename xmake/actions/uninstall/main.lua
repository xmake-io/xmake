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
import("core.platform.platform")
import("uninstall")

-- main
function main()

    -- get the target name
    local targetname = option.get("target")

    -- config it first
    task.run("config", {target = targetname})

    -- trace
    print("uninstalling from %s ...", option.get("installdir") or platform.get("installdir"))

    -- attempt to uninstall directly
    try
    {
        function ()

            -- uninstall target
            uninstall.uninstall(targetname)

            -- trace
            cprint("${bright}uninstall ok!${clear}${ok_hand}")
        end,

        catch
        {
            -- failed or not permission? request administrator permission and uninstall it again
            function (errors)

                -- show tips
                cprint("${bright red}error: ${default red}failed to uninstall, may permission denied!")

                -- continue to uninstall with administrator permission?
                if os.feature("sudo") then

                    -- show tips
                    cprint("${bright yellow}note: ${default yellow}try continue to uninstall with administrator permission again?")
                    cprint("please input: y (y/n)")

                    -- get answer
                    io.flush()
                    local answer = io.read()
                    if answer == 'y' or answer == '' then

                        -- uninstall target with administrator permission
                        os.sudol(os.runv, path.join(os.scriptdir(), "uninstall_admin.lua"), {targetname or "__all", option.get("installdir")})

                        -- trace
                        cprint("${bright}uninstall ok!${clear}${ok_hand}")
                    end
                end
            end
        }
    }
end
