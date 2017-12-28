--!A cross-platform build utility based on Lua
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
-- Copyright (C) 2015 - 2018, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        main.lua
--

-- imports
import("core.base.option")
import("core.base.task")
import("core.platform.platform")
import("core.base.privilege")
import("privilege.sudo")
import("install")

-- get install directory
function _installdir()

    -- the install directory
    --
    -- DESTDIR: be compatible with https://www.gnu.org/prep/standards/html_node/DESTDIR.html
    --
    local installdir = option.get("installdir") or os.getenv("INSTALLDIR") or os.getenv("DESTDIR") or platform.get("installdir")
    assert(installdir, "unknown install directory!")

    -- append prefix
    local prefix = option.get("prefix") or os.getenv("PREFIX")
    if prefix then
        installdir = path.join(installdir, prefix)
    end

    -- ok
    return installdir
end

-- main
function main()

    -- get the target name
    local targetname = option.get("target")

    -- build it first
    task.run("build", {target = targetname, all = option.get("all")})

    -- get install directory
    local installdir = _installdir()

    -- trace
    print("installing to %s ...", installdir)

    -- attempt to install directly
    try
    {
        function ()

            -- install target
            install(targetname or ifelse(option.get("all"), "__all", "__def"), installdir)

            -- trace
            cprint("${bright}install ok!${clear}${ok_hand}")
        end,

        catch
        {
            -- failed or not permission? request administrator permission and install it again
            function (errors)

                -- try get privilege
                if privilege.get() then
                    local ok = try
                    {
                        function ()

                            -- install target
                            install(targetname or ifelse(option.get("all"), "__all", "__def"), installdir)

                            -- trace
                            cprint("${bright}install ok!${clear}${ok_hand}")

                            -- ok
                            return true
                        end
                    }

                    -- release privilege
                    privilege.store()

                    -- ok?
                    if ok then return end
                end

                -- show tips
                cprint("${bright red}error: ${default red}installation failed, may permission denied!")

                -- continue to install with administrator permission?
                if sudo.has() then

                    -- get confirm
                    local confirm = option.get("yes")
                    if confirm == nil then

                        -- show tips
                        cprint("${bright yellow}note: ${default yellow}try continue to install with administrator permission again?")
                        cprint("please input: y (y/n)")

                        -- get answer
                        io.flush()
                        local answer = io.read()
                        if answer == 'y' or answer == '' then
                            confirm = true
                        end
                    end

                    -- confirm to install?
                    if confirm then

                        -- install target with administrator permission
                        sudo.runl(path.join(os.scriptdir(), "install_admin.lua"), {targetname or ifelse(option.get("all"), "__all", "__def"), installdir})

                        -- trace
                        cprint("${bright}install ok!${clear}${ok_hand}")
                    end
                end
            end
        }
    }
end
