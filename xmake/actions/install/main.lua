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
import("install")

-- main
function main()

    -- get the target name
    local targetname = option.get("target")

    -- build it first
    task.run("build", {target = targetname, all = option.get("all")})

    -- trace
    print("installing to %s ...", option.get("installdir") or platform.get("installdir"))

    -- attempt to install directly
    try
    {
        function ()

            -- install target
            install.install(targetname or ifelse(option.get("all"), "__all", "__def"))

            -- trace
            cprint("${bright}install ok!${clear}${ok_hand}")
        end,

        catch
        {
            -- failed or not permission? request administrator permission and install it again
            function (errors)

                -- show tips
                cprint("${bright red}error: ${default red}installation failed, may permission denied!")

                -- continue to install with administrator permission?
                if os.feature("sudo") then

                    -- show tips
                    cprint("${bright yellow}note: ${default yellow}try continue to install with administrator permission again?")
                    cprint("please input: y (y/n)")

                    -- get answer
                    io.flush()
                    local answer = io.read()
                    if answer == 'y' or answer == '' then

                        -- install target with administrator permission
                        os.sudol(os.runv, path.join(os.scriptdir(), "install_admin.lua"), {targetname or ifelse(option.get("all"), "__all", "__def"), option.get("installdir")})

                        -- trace
                        cprint("${bright}install ok!${clear}${ok_hand}")
                    end
                end
            end
        }
    }
end
