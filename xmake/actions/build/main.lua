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
import("core.base.global")
import("core.base.task")
import("core.project.rule")
import("core.project.config")
import("core.project.project")
import("core.platform.platform")
import("core.theme.theme")
import("utils.progress")
import("build")
import("build_files")
import("cleaner")
import("statistics")
import("check", {alias = "check_targets"})
import("private.cache.build_cache")
import("private.service.remote_build.action", {alias = "remote_build_action"})

-- try building it
function _do_try_build(configfile, tool, trybuild, trybuild_detected, targetname)
    if configfile and tool and (trybuild or utils.confirm({default = true,
            description = "${bright}" .. path.filename(configfile) .. "${clear} found, try building it or you can run `${bright}xmake f --trybuild=${clear}` to set buildsystem"})) then
        if not trybuild then
            task.run("config", {trybuild = trybuild_detected})
        end
        tool.build()
        return true
    end
end

-- do build for the third-party buildsystem
function _try_build()

    -- load config
    config.load()

    -- rebuild it? do clean first
    local targetname = option.get("target")
    if option.get("rebuild") then
        task.run("clean", {target = targetname})
    end

    -- get the buildsystem tool
    local configfile = nil
    local tool = nil
    local trybuild = config.get("trybuild")
    local trybuild_detected = nil
    if trybuild then
        tool = import("private.action.trybuild." .. trybuild, {try = true, anonymous = true})
        if tool then
            configfile = tool.detect()
        else
            raise("unknown build tool: %s", trybuild)
        end
        return _do_try_build(configfile, tool, trybuild, trybuild_detected, targetname)
    else
        for _, name in ipairs({"xrepo", "autoconf", "cmake", "meson", "scons", "bazel", "msbuild", "xcodebuild", "make", "ninja", "ndkbuild"}) do
            tool = import("private.action.trybuild." .. name, {anonymous = true})
            configfile = tool.detect()
            if configfile then
                trybuild_detected = name
                if _do_try_build(configfile, tool, trybuild, trybuild_detected, targetname) then
                    return true
                end
            end
        end
    end
end

-- do global project rules
function _do_project_rules(scriptname, opt)
    for _, rulename in ipairs(project.get("target.rules")) do
        local r = project.rule(rulename) or rule.rule(rulename)
        if r and r:kind() == "project" then
            local buildscript = r:script(scriptname)
            if buildscript then
                buildscript(opt)
            end
        end
    end
end

-- do build
function _do_build(targetname, group_pattern)
    local sourcefiles = option.get("files")
    if sourcefiles then
        build_files(targetname, group_pattern, sourcefiles)
    else
        build(targetname, group_pattern)
    end
end

-- on exit
function _on_exit(ok, errors)

    -- since we call it in both os.atexit and catch block,
    -- we need to avoid duplicate execution.
    local handled = false
    local exited = _g.exited
    if not exited then
        exited = true
        handled = true
        _g.exited = exited
    end

    -- we just handle the build failure
    if handled and not ok then
        check_targets(targetname, {build_failure = true})
    end
end

-- main
function main()

    -- try building it using third-party buildsystem if xmake.lua not exists
    if not os.isfile(project.rootfile()) and _try_build() then
        return
    end

    -- post statistics before locking project
    statistics.post()

    -- do action for remote?
    if remote_build_action.enabled() then
        return remote_build_action()
    end

    -- lock the whole project
    project.lock()

    -- config it first
    local targetname
    local group_pattern = option.get("group")
    if group_pattern then
        group_pattern = "^" .. path.pattern(group_pattern) .. "$"
    else
        targetname = option.get("target")
    end
    task.run("config", {}, {disable_dump = true})

    -- enter project directory
    local oldir = os.cd(project.directory())

    -- clean up temporary files once a day
    cleaner.cleanup()

    -- register exit callbacks
    os.atexit(_on_exit)

    try
    {
        function ()

            -- do check
            check_targets(targetname, {build = true})

            -- do rules before building
            _do_project_rules("build_before")

            -- do build
            _do_build(targetname, group_pattern)

            -- dump cache stats
            if option.get("diagnosis") then
                build_cache.dump_stats()
            end
        end,
        catch
        {
            function (errors)

                -- maybe it's unreachable when building fails, so we need also os.atexit()
                -- @see https://github.com/xmake-io/xmake/issues/3401
                _on_exit(false, errors)

                -- do rules after building
                _do_project_rules("build_after", {errors = errors})

                -- raise
                if errors then
                    raise(errors)
                elseif group_pattern then
                    raise("build targets with group(%s) failed!", group_pattern)
                elseif targetname then
                    raise("build target: %s failed!", targetname)
                else
                    raise("build target failed!")
                end
            end
        }
    }

    -- do rules after building
    _do_project_rules("build_after")

    -- unlock the whole project
    project.unlock()

    -- leave project directory
    os.cd(oldir)

    -- trace
    progress.show(100, "${color.success}build ok!")
end
