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
-- Copyright (C) 2015-present, TBOOX Open Source Group.
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

    -- config it first
    local targetname = option.get("target")
    task.run("config", {target = targetname, require = "n", verbose = false})

    -- attempt to uninstall directly
    try
    {
        function ()
            uninstall(targetname)
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
                            uninstall(targetname)
                            cprint("${color.success}uninstall ok!")
                            return true
                        end
                    }

                    -- release privilege
                    privilege.store()
                    if ok then
                        return
                    end
                end

                -- continue to uninstall with administrator permission?
                local ok = false
                if sudo.has() and option.get("admin") then

                    -- uninstall target with administrator permission
                    sudo.execl(path.join(os.scriptdir(), "uninstall_admin.lua"), {targetname or "__all", option.get("installdir"), option.get("prefix")})

                    -- trace
                    cprint("${color.success}uninstall ok!")
                    ok = true
                end
                if not ok then
                    local syserror = os.syserror()
                    if syserror == os.SYSERR_NOT_PERM or syserror == os.SYSERR_NOT_ACCESS then
                        wprint("please pass the --admin parameter to `xmake uninstall` to request administrator permissions!")
                    end
                end
                assert(ok, "uninstall failed, %s", errors or "unknown reason")
            end
        }
    }
end
