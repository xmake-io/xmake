--!A cross-platform build utility based on Lua
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--
-- Copyright (C) 2015-2020, TBOOX Open Source Group.
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
import("uninstall")

-- main
function main()

    -- get the target name
    local targetname = option.get("target")

    -- config it first
    task.run("config", {target = targetname, require = "n", verbose = false})

    -- attempt to uninstall directly
    try
    {
        function ()

            -- uninstall target
            uninstall(targetname)

            -- trace
            cprint("${color.success}uninstall ok!")
        end,

        catch
        {
            -- failed or not permission? request administrator permission and uninstall it again
            function (errors)

                -- try get privilege
                if privilege.get() then
                    local ok = try
                    {
                        function ()

                            -- uninstall target
                            uninstall(targetname)

                            -- trace
                            cprint("${color.success}uninstall ok!")

                            -- ok
                            return true
                        end
                    }

                    -- release privilege
                    privilege.store()

                    -- ok?
                    if ok then return end
                end

                -- continue to uninstall with administrator permission?
                local ok = false
                if sudo.has() and option.get("admin") then

                    -- uninstall target with administrator permission
                    sudo.runl(path.join(os.scriptdir(), "uninstall_admin.lua"), {targetname or "__all", option.get("installdir"), option.get("prefix")})

                    -- trace
                    cprint("${color.success}uninstall ok!")
                    ok = true
                end
                if not ok and os.syserror() == os.SYSERR_NOT_PERM then
                    wprint("please pass the --admin parameter to `xmake uninstall` to request administrator permissions!")
                end
                assert(ok, "uninstall failed, %s", errors or "unknown reason")
            end
        }
    }
end
