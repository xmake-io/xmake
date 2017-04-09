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
-- @file        main.lua
--

-- imports
import("core.base.option")
import("core.project.task")
import("core.project.config")
import("core.project.global")
import("core.project.project")
import("core.platform.platform")
import("core.tool.debugger")

-- run binary target
function _run_binary(target)

    -- debugging?
    if option.get("debug") then

        -- debug it
        debugger.run(target:targetfile(), option.get("arguments"))
    else

        -- run it
        os.execv(target:targetfile(), option.get("arguments"))
    end
end

-- run target 
function _run_target(target)

    -- get kind
    local kind = target:get("kind")
    if not kind then
        return 
    end

    -- get script 
    local scripts =
    {
        binary = _run_binary
    }

    -- check
    assert(scripts[kind], "this target(%s) with kind(%s) can not be executed!", target:name(), kind)

    -- run it
    scripts[kind](target) 
end

-- run the given target 
function _run(target)

    -- the target scripts
    local scripts =
    {
        target:get("run_before")
    ,   target:get("run") or _run_target
    ,   target:get("run_after")
    }

    -- run the target scripts
    for i = 1, 3 do
        local script = scripts[i]
        if script ~= nil then
            script(target)
        end
    end
end

-- main
function main()

    -- get the target name
    local targetname = option.get("target")

    -- build it first
    task.run("build", {target = targetname, all = option.get("all")})

    -- enter project directory
    local olddir = os.cd(project.directory())

    -- run the given target?
    if targetname then
        _run(project.target(targetname))
    else
        -- run default or all binary targets
        for _, target in pairs(project.targets()) do
            local default = target:get("default")
            if (default == nil or default == true or option.get("all")) and target:get("kind") == "binary" then
                _run(target)
            end
        end
    end

    -- leave project directory
    os.cd(olddir)
end
