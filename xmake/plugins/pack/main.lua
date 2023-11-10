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
import("core.base.task")
import("core.base.option")
import("core.project.project")
import("private.service.remote_build.action", {alias = "remote_build_action"})
import("actions.build.main", {rootdir = os.programdir(), alias = "build_action"})
import("xpack")

function _pack_package(package)
    assert(package:formats(), "xpack(%s): formats not found, please use `set_formats()` to set it.", package:name())
    for _, format in package:formats():keys() do
        package:format_set(format)
        import(format)(package)
    end
end

function _pack_packages()
    for _, package in pairs(xpack.packages()) do
        _pack_package(package)
    end
end

function _build_targets()
    local targetnames = {}
    for _, package in pairs(xpack.packages()) do
        local targets = package:get("targets")
        if targets then
            table.join2(targetnames, targets)
        end
    end
    if #targetnames > 0 then
        build_action.build_targets(targetnames)
    end
end

function main()

    -- do action for remote?
    if remote_build_action.enabled() then
        return remote_build_action()
    end

    -- lock the whole project
    project.lock()

    -- load config first
    task.run("config", {}, {disable_dump = true})

    -- load targets
    project.load_targets()

    -- enter project directory
    local oldir = os.cd(project.directory())

    -- build targets first
    _build_targets()

    -- do pack
    _pack_packages()

    -- leave project directory
    os.cd(oldir)

    -- unlock the whole project
    project.unlock()
end


