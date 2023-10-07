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
import("async.runjobs")
import("private.action.run.runenvs")
import("private.service.remote_build.action", {alias = "remote_build_action"})
import("actions.build.main", {rootdir = os.programdir(), alias = "build_action"})

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

    -- build run environments
    local addenvs, setenvs = runenvs.make(target)

    -- get run arguments
    local args = table.wrap(option.get("arguments") or target:get("runargs"))

    -- debugging?
    if option.get("debug") then
        debugger.run(targetfile, args, {curdir = rundir, addenvs = addenvs, setenvs = setenvs})
    else
        local envs = runenvs.join(addenvs, setenvs)
        os.execv(targetfile, args, {curdir = rundir, detach = option.get("detach"), envs = envs})
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

-- run tests
function _run_tests(tests)
end

function main()

    -- do action for remote?
    if remote_build_action.enabled() then
        return remote_build_action()
    end

    -- lock the whole project
    project.lock()

    -- load config first
    config.load()

    -- load targets
    project.load_targets()

    -- get tests
    local tests = {}
    local group_pattern = option.get("group")
    if group_pattern then
        group_pattern = "^" .. path.pattern(group_pattern) .. "$"
    end
    for _, target in ipairs(project.ordertargets()) do
        if target:is_binary() or target:script("run") then
            for _, name in ipairs(target:get("tests")) do
                local info = {target = target}
                local extra = target:extraconf("tests", name)
                if extra then
                    table.join2(info, extra)
                end
                if not info.group then
                    info.group = target:get("group")
                end
                if not info.rundir then
                    info.rundir = target:rundir()
                end
                if not info.runenvs then
                    local addenvs, setenvs = runenvs.make(target)
                    local envs = runenvs.join(addenvs, setenvs)
                    info.runenvs = envs
                end

                local group = info.group
                if (not group_pattern) or option.get("all") or (group_pattern and group and group:match(group_pattern)) then
                    tests[name] = info
                end
            end
        end
    end
    local test_patterns = option.get("tests")
    if test_patterns then
        local tests_new = {}
        for _, pattern in ipairs(test_patterns) do
            pattern = "^" .. path.pattern(pattern) .. "$"
            for name, info in pairs(tests) do
                if name:match(pattern) then
                    tests_new[name] = info
                end
            end
        end
        tests = tests_new
    end

    -- enter project directory
    local oldir = os.cd(project.directory())

    -- build targets with the given tests first
    local targetnames = {}
    for _, info in table.orderpairs(tests) do
        table.insert(targetnames, info.target:name())
    end
    build_action.build_targets(targetnames)

    -- run tests
    _run_tests(tests)

    -- leave project directory
    os.cd(oldir)

    -- unlock the whole project
    project.unlock()
end

