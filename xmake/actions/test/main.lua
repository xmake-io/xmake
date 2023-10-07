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
import("async.runjobs")
import("private.action.run.runenvs")
import("private.service.remote_build.action", {alias = "remote_build_action"})
import("actions.build.main", {rootdir = os.programdir(), alias = "build_action"})

-- test target
function _do_test_target(target, opt)
    opt = opt or {}

    -- get run environments
    local envs = opt.runenvs
    if not envs then
        local addenvs, setenvs = runenvs.make(target)
        envs = runenvs.join(addenvs, setenvs)
    end

    -- run test
    local outdata
    local rundir = opt.rundir or target:rundir()
    local targetfile = path.absolute(target:targetfile())
    local runargs = table.wrap(opt.runargs or target:get("runargs"))
    local ok = try {
        function ()
            outdata = os.iorunv(targetfile, runargs, {curdir = rundir, envs = envs})
            return true
        end
    }

    if ok then
        local passed
        outdata = outdata or ""
        for _, pass_output in ipairs(opt.pass_outputs) do
            if opt.plain then
                if pass_output == outdata then
                    passed = true
                    break
                end
            else
                if outdata:match("^" .. pass_output .. "$") then
                    passed = true
                    break
                end
            end
        end
        for _, fail_output in ipairs(opt.fail_outputs) do
            if opt.plain then
                if fail_output == outdata then
                    passed = false
                    break
                end
            else
                if outdata:match("^" .. fail_output .. "$") then
                    passed = false
                    break
                end
            end
        end
        if passed == nil then
            passed = true
        end
        return passed
    end
end

-- test target
function _on_test_target(target, opt)

    -- build target with rules
    local passed
    local done = false
    for _, r in ipairs(target:orderules()) do
        local on_test = r:script("test")
        if on_test then
            passed = on_test(target, opt)
            done = true
        end
    end
    if done then
        return passed
    end

    -- do test
    return _do_test_target(target, opt)
end

-- recursively add target envs
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

-- run the given test
function _run_test(test)

    -- this target has been disabled?
    local target = test.target
    test.target = nil

    -- enter the environments of the target packages
    local oldenvs = os.getenvs()
    _add_target_pkgenvs(target, {})

    -- the target scripts
    local scripts =
    {
        target:script("test_before")
    ,   function (target, opt)
            for _, r in ipairs(target:orderules()) do
                local before_test = r:script("test_before")
                if before_test then
                    before_test(target, opt)
                end
            end
        end
    ,   target:script("test", _on_test_target)
    ,   function (target, opt)
            for _, r in ipairs(target:orderules()) do
                local after_test = r:script("test_after")
                if after_test then
                    after_test(target, opt)
                end
            end
        end
    ,   target:script("test_after")
    }

    -- run the target scripts
    local passed
    for i = 1, 5 do
        local script = scripts[i]
        if script ~= nil then
            local ok = script(target, test)
            if i == 3 then
                passed = ok
            end
        end
    end

    -- leave the environments of the target packages
    os.setenvs(oldenvs)
    return passed
end

-- run tests
function _run_tests(tests)
    local ordertests = {}
    for name, testinfo in table.orderpairs(tests) do
        table.insert(ordertests, testinfo)
    end
    if #ordertests == 0 then
        print("nothing to test")
        return
    end

    -- do test
    local spent = os.mclock()
    print("running tests ...")
    local report = {passed = 0, total = #ordertests}
    local jobs = tonumber(option.get("jobs") or "1")
    runjobs("run_tests", function (index)
        local testinfo = ordertests[index]
        if testinfo then
            local passed = _run_test(testinfo)
            if passed then
                report.passed = report.passed + 1
            end
        end
    end, {total = #ordertests,
          comax = jobs,
          isolate = true})

    -- generate report
    spent = os.mclock() - spent
    local passed_rate = math.floor(report.passed * 100 / report.total)
    cprint("${color.success}%3d%%${clear} tests passed, ${color.failure}%d${clear} tests failed out of ${bright}%d${clear}, spent ${bright}%0.3fs",
        passed_rate, report.total - report.passed, report.total, spent / 1000)
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
                local testinfo = {name = name, target = target}
                local extra = target:extraconf("tests", name)
                if extra then
                    table.join2(testinfo, extra)
                end
                if not testinfo.group then
                    testinfo.group = target:get("group")
                end

                local group = testinfo.group
                if (not group_pattern) or option.get("all") or (group_pattern and group and group:match(group_pattern)) then
                    tests[name] = testinfo
                end
            end
        end
    end
    local test_patterns = option.get("tests")
    if test_patterns then
        local tests_new = {}
        for _, pattern in ipairs(test_patterns) do
            pattern = "^" .. path.pattern(pattern) .. "$"
            for name, testinfo in pairs(tests) do
                if name:match(pattern) then
                    tests_new[name] = testinfo
                end
            end
        end
        tests = tests_new
    end

    -- enter project directory
    local oldir = os.cd(project.directory())

    -- build targets with the given tests first
    local targetnames = {}
    for _, testinfo in table.orderpairs(tests) do
        table.insert(targetnames, testinfo.target:name())
    end
    build_action.build_targets(targetnames)

    -- run tests
    _run_tests(tests)

    -- leave project directory
    os.cd(oldir)

    -- unlock the whole project
    project.unlock()
end

