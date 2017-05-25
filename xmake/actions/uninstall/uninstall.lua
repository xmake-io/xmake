--!The Make-like Build Utility based on Lua
--
-- Licensed to the Apache Software Foundation (ASF) under one
-- or more contributor license agreements.  See the NOTICE file
-- distributed with this work for additional information
-- regarding copyright ownership.  The ASF licenses this file
-- to you under the Apache License, Version 2.0 (the
-- "License"); you may not use this file except in compliance
-- with the License.  You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- 
-- Copyright (C) 2015 - 2017, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        uninstall.lua
--

-- imports
import("core.project.task")
import("core.project.project")
import("core.platform.platform")

-- uninstall the given target 
function _uninstall_target(target)

    -- enter project directory
    local olddir = os.cd(project.directory())

    -- the target scripts
    local scripts =
    {
        target:get("uninstall_before")
    ,   target:get("uninstall") or platform.get("uninstall")
    ,   target:get("uninstall_after")
    }

    -- uninstall the target scripts
    for i = 1, 3 do
        local script = scripts[i]
        if script ~= nil then
            script(target)
        end
    end

    -- leave project directory
    os.cd(olddir)
end

-- uninstall the given target and deps
function _uninstall_target_and_deps(target)

    -- this target have been finished?
    if _g.finished[target:name()] then
        return 
    end

    -- uninstall for all dependent targets
    for _, depname in ipairs(target:get("deps")) do
        _uninstall_target_and_deps(project.target(depname)) 
    end

    -- uninstall target
    _uninstall_target(target)

    -- finished
    _g.finished[target:name()] = true
end

-- uninstall
function main(targetname)

    -- init finished states
    _g.finished = {}

    -- uninstall given target?
    if targetname then
        _uninstall_target_and_deps(project.target(targetname))
    else
        -- uninstall all targets
        for _, target in pairs(project.targets()) do
            _uninstall_target_and_deps(target)
        end
    end
end
