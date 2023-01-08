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
import("core.project.config")
import("core.project.project")
import("core.platform.platform")
import("core.base.privilege")
import("privilege.sudo")
import("install")

-- check targets
function _check_targets(targetname, group_pattern)

    -- get targets
    local targets = {}
    if targetname then
        table.insert(targets, project.target(targetname))
    else
        -- install default or all targets
        for _, target in pairs(project.targets()) do
            local group = target:get("group")
            if (target:is_default() and not group_pattern) or option.get("all") or (group_pattern and group and group:match(group_pattern)) then
                table.insert(targets, target)
            end
        end
    end

    -- filter and check targets with builtin-install script
    local targetnames = {}
    for _, target in ipairs(targets) do
        if target:targetfile() and target:is_enabled() and not target:script("install") then
            local targetfile = target:targetfile()
            if targetfile and not os.isfile(targetfile) then
                table.insert(targetnames, target:name())
            end
        end
    end

    -- there are targets that have not yet been built?
    if #targetnames > 0 then
        raise("please run `$xmake build [target]` to build the following targets first:\n  -> " .. table.concat(targetnames, '\n  -> '))
    end
end

-- main
function main()

    -- local config first
    config.load()

    -- check targets first
    local targetname
    local group_pattern = option.get("group")
    if group_pattern then
        group_pattern = "^" .. path.pattern(group_pattern) .. "$"
    else
        targetname = option.get("target")
    end
    _check_targets(targetname, group_pattern)

    -- attempt to install directly
    try
    {
        function ()
            install(targetname or (option.get("all") and "__all" or "__def"), group_pattern)
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
                            install(targetname or (option.get("all") and "__all" or "__def"), group_pattern)
                            cprint("${color.success}install ok!")
                            return true
                        end
                    }

                    -- release privilege
                    privilege.store()
                    if ok then
                        return
                    end
                end

                -- continue to install with administrator permission?
                local ok = false
                if sudo.has() and option.get("admin") then

                    -- install target with administrator permission
                    sudo.execl(path.join(os.scriptdir(), "install_admin.lua"), {targetname or (option.get("all") and "__all" or "__def"), group_pattern, option.get("installdir"), option.get("prefix")})
                    cprint("${color.success}install ok!")
                    ok = true
                end
                if not ok then
                    local syserror = os.syserror()
                    if syserror == os.SYSERR_NOT_PERM or syserror == os.SYSERR_NOT_ACCESS then
                        wprint("please pass the --admin parameter to `xmake install` to request administrator permissions!")
                    end
                end
                assert(ok, "install failed, %s", errors or "unknown reason")
            end
        }
    }
end
