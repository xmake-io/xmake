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
import("core.base.global")
import("core.project.project")
import("core.platform.platform")
import("devel.debugger")
import("private.async.runjobs")
import("private.action.run.make_runenvs")
import("private.service.remote_build.action", {alias = "remote_build_action"})

-- run target
function _do_run_target(target)

    -- only for binary program
    if not target:is_binary() then
        return
    end

    -- get the run directory of target
    local rundir = target:rundir()

    -- get the absolute target file path
    local targetfile = path.absolute(target:targetfile())

    -- add run environments
    local addrunenvs, setrunenvs = make_runenvs(target)
    for name, values in pairs(addrunenvs) do
        os.addenv(name, table.unpack(table.wrap(values)))
    end
    for name, value in pairs(setrunenvs) do
        os.setenv(name, table.unpack(table.wrap(value)))
    end

    -- get run arguments
    local args = table.wrap(option.get("arguments") or target:get("runargs"))

    -- debugging?
    if option.get("debug") then
        debugger.run(targetfile, args, {curdir = rundir})
    else
        os.execv(targetfile, args, {curdir = rundir, detach = option.get("detach")})
    end
end

-- run target
function _on_run_target(target)

    -- build target with rules
    local done = false
    for _, r in ipairs(target:orderules()) do
        local on_run = r:script("run")
        if on_run then
            on_run(target)
            done = true
        end
    end
    if done then return end

    -- do run
    _do_run_target(target)
end

-- recursively target add env
function _add_target_pkgenvs(target, targets_added)
    if targets_added[target:name()] then
        return
    end
    targets_added[target:name()] = true
    os.addenvs(target:pkgenvs())
    for _, dep in ipairs(target:orderdeps()) do
        _add_target_pkgenvs(dep, targets_added)
    end
end

-- find target names matching a specific name
function _find_matching_target_names(targetname)
    targetname = targetname:lower()
    local matching_targetnames = {}
    for _, target in ipairs(project.ordertargets()) do
        if target:name():lower():find(targetname, 1, true) then
            table.insert(matching_targetnames, target:name())
        end
    end

    table.sort(matching_targetnames)
    return matching_targetnames
end

-- run the given target
function _run(target)

    -- has been disabled?
    if not target:is_enabled() then
        return
    end

    -- enter the environments of the target packages
    local oldenvs = os.getenvs()
    _add_target_pkgenvs(target, {})

    -- the target scripts
    local scripts =
    {
        target:script("run_before")
    ,   function (target)
            for _, r in ipairs(target:orderules()) do
                local before_run = r:script("run_before")
                if before_run then
                    before_run(target)
                end
            end
        end
    ,   target:script("run", _on_run_target)
    ,   function (target)
            for _, r in ipairs(target:orderules()) do
                local after_run = r:script("run_after")
                if after_run then
                    after_run(target)
                end
            end
        end
    ,   target:script("run_after")
    }

    -- run the target scripts
    for i = 1, 5 do
        local script = scripts[i]
        if script ~= nil then
            script(target)
        end
    end

    -- leave the environments of the target packages
    os.setenvs(oldenvs)
end

-- check targets
function _check_targets(targetname, group_pattern)

    -- get targets
    local targets = {}
    if targetname then
        local target = project.target(targetname)
        if not target then
            -- check if the name is part of other target to help
            local possible_targetnames = _find_matching_target_names(targetname)
            local errors = targetname .. " is not a valid target name for this project"
            if #possible_targetnames > 0 then
                errors = errors .. "\nlist of valid target names close to your input:\n - " .. table.concat(possible_targetnames, '\n - ')
            end
            raise(errors)
        end

        table.insert(targets, target)
    else
        for _, target in ipairs(project.ordertargets()) do
            if target:is_binary() then
                local group = target:get("group")
                if (target:is_default() and not group_pattern) or option.get("all") or (group_pattern and group and group:match(group_pattern)) then
                    table.insert(targets, target)
                end
            end
        end
    end

    -- filter and check targets with builtin-run script
    local targetnames = {}
    for _, target in ipairs(targets) do
        if target:targetfile() and target:is_enabled() and not target:script("run") then
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

    -- do action for remote?
    if remote_build_action.enabled() then
        return remote_build_action()
    end

    -- load config first
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

    -- enter project directory
    local oldir = os.cd(project.directory())

    -- run the given target?
    if targetname then
        _run(project.target(targetname))
    else
        local targets = {}
        for _, target in ipairs(project.ordertargets()) do
            if target:is_binary() then
                local group = target:get("group")
                if (target:is_default() and not group_pattern) or option.get("all") or (group_pattern and group and group:match(group_pattern)) then
                    table.insert(targets, target)
                end
            end
        end
        local jobs = tonumber(option.get("jobs") or "1")
        runjobs("run_targets", function (index)
            local target = targets[index]
            if target then
                _run(target)
            end
        end, {total = #targets,
              comax = jobs,
              isolate = true})
    end

    -- leave project directory
    os.cd(oldir)
end

