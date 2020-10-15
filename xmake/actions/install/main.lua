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
import("core.project.project")
import("core.platform.platform")
import("core.base.privilege")
import("privilege.sudo")
import("install")

-- check targets
function _check_targets(targetname)

    -- get targets
    local targets = {}
    if targetname and not targetname:startswith("__") then
        table.insert(targets, project.target(targetname))
    else
        -- install default or all targets
        for _, target in pairs(project.targets()) do
            local default = target:get("default")
            if default == nil or default == true or targetname == "__all" then
                table.insert(targets, target)
            end
        end
    end

    -- filter and check targets with builtin-install script
    local targetnames = {}
    for _, target in ipairs(targets) do
        if not target:isphony() and target:get("enabled") ~= false and not target:script("install") then
            local targetfile = target:targetfile()
            if targetfile and not os.isfile(targetfile) then
                table.insert(targetnames, target:name())
            end
        end
    end

    -- there are targets that have not yet been built?
    if #targetnames > 0 then
        raise("please run `$xmake [target]` to build the following targets first:\n  -> " .. table.concat(targetnames, '\n  -> '))
    end
end

-- main
function main()

    -- get the target name
    local targetname = option.get("target")

    -- config it first
    task.run("config", {target = targetname, require = "n", verbose = false})

    -- check targets first
    _check_targets(targetname)

    -- attempt to install directly
    try
    {
        function ()

            -- install target
            install(targetname or ifelse(option.get("all"), "__all", "__def"))

            -- trace
            cprint("${color.success}install ok!")
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
                            install(targetname or ifelse(option.get("all"), "__all", "__def"))

                            -- trace
                            cprint("${color.success}install ok!")

                            -- ok
                            return true
                        end
                    }

                    -- release privilege
                    privilege.store()

                    -- ok?
                    if ok then return end
                end

                -- continue to install with administrator permission?
                local ok = false
                if sudo.has() and option.get("admin") then

                    -- install target with administrator permission
                    sudo.runl(path.join(os.scriptdir(), "install_admin.lua"), {targetname or ifelse(option.get("all"), "__all", "__def"), option.get("installdir"), option.get("prefix")})

                    -- trace
                    cprint("${color.success}install ok!")
                    ok = true
                end
                if not ok and os.syserror() == os.SYSERR_NOT_PERM then
                    wprint("please pass the --admin parameter to `xmake install` to request administrator permissions!")
                end
                assert(ok, "install failed, %s", errors or "unknown reason")
            end
        }
    }
end
