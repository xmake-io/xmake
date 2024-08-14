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
import("core.project.rule")
import("core.project.config")
import("core.base.global")
import("core.project.project")
import("core.platform.platform")
import("private.action.clean.remove_files")
import("target.action.clean", {alias = "_do_clean_target"})
import("private.service.remote_build.action", {alias = "remote_build_action"})

-- on clean target
function _on_clean_target(target)

    -- build target with rules
    local done = false
    for _, r in ipairs(target:orderules()) do
        local on_clean = r:script("clean")
        if on_clean then
            on_clean(target)
            done = true
        end
    end
    if done then return end

    -- do clean
    _do_clean_target(target)
end

-- clean the given target files
function _clean_target(target)

    -- has been disabled?
    if not target:is_enabled() then
        return
    end

    -- enter the environments of the target packages
    local oldenvs = os.addenvs(target:pkgenvs())

    -- the target scripts
    local scripts =
    {
        target:script("clean_before")
    ,   function (target)
            for _, r in ipairs(target:orderules()) do
                local before_clean = r:script("clean_before")
                if before_clean then
                    before_clean(target)
                end
            end
        end
    ,   target:script("clean", _on_clean_target)
    ,   function (target)
            for _, r in ipairs(target:orderules()) do
                local after_clean = r:script("clean_after")
                if after_clean then
                    after_clean(target)
                end
            end
        end
    ,   target:script("clean_after")
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

-- clean the given targets
function _clean_targets(targets)
    for _, target in ipairs(targets) do
        _clean_target(target)
    end
end

-- clean target
function _clean(targetname)
    if targetname then
        local target = project.target(targetname)
        _clean_target(target)
    else
        _clean_targets(project.ordertargets())
    end
end

-- clean configuration cache
function _clean_configs()
    if option.get("all") then
        -- we need to close it first after removing file lock
        project.filelock():close()
        remove_files(config.directory())
    end
end

-- do clean for the third-party buildsystem
function _try_clean()

    -- load config
    config.load()

    -- get the buildsystem tool
    local configfile = nil
    local tool = nil
    local trybuild = config.get("trybuild")
    if trybuild then
        tool = import("private.action.trybuild." .. trybuild, {try = true, anonymous = true})
        if tool then
            configfile = tool.detect()
        end
    end

    -- try cleaning it
    if configfile and tool and trybuild then
        tool.clean()
    end
end

function main()

    -- try cleaning it using third-party buildsystem if xmake.lua not exists
    if not os.isfile(project.rootfile()) then
        return _try_clean()
    end

    -- do action for remote?
    if remote_build_action.enabled() then
        return remote_build_action()
    end

    -- load config first
    task.run("config", {require = false}, {disable_dump = true})

    -- lock the whole project
    project.lock()

    -- get the target name
    local targetname = option.get("target")

    -- enter project directory
    local oldir = os.cd(project.directory())

    -- clean target
    _clean(targetname)

    -- unlock the whole project
    project.unlock()

    -- we must call it after unlocking project because it will remove project lockfile
    _clean_configs()

    -- leave project directory
    os.cd(oldir)
end
