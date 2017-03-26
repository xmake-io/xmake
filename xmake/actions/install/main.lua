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

-- install the given target 
function _install_target(target)

    -- enter project directory
    local olddir = os.cd(project.directory())

    -- the target scripts
    local scripts =
    {
        target:get("install_before")
    ,   target:get("install") or platform.get("install")
    ,   target:get("install_after")
    }

    -- install the target scripts
    for i = 1, 3 do
        local script = scripts[i]
        if script ~= nil then
            script(target)
        end
    end

    -- leave project directory
    os.cd(olddir)
end

-- install the given target and deps
function _install_target_and_deps(target)

    -- this target have been finished?
    if _g.finished[target:name()] then
        return 
    end

    -- install for all dependent targets
    for _, depname in ipairs(target:get("deps")) do
        _install_target_and_deps(project.target(depname)) 
    end

    -- install target
    _install_target(target)

    -- finished
    _g.finished[target:name()] = true
end

-- main
function main()

    -- get the target name
    local targetname = option.get("target")

    -- init finished states
    _g.finished = {}

    try{
        function ()
            task.run("safe_config", {target = targetname})
            -- install all?
            if targetname == "all" then
                for _, target in pairs(project.targets()) do
                    _install_target_and_deps(target)
                end
            else
                _install_target_and_deps(project.target(targetname))
            end
        end,
        catch
        {
            function (errors)
                -- print user-friendly notes
                cprint("${bright red}error: ${default red}installation fail. may it hasn't built before or permission denied")
                cprint("${bright yellow}note: ${default yellow}try `xmake;sudo xmake install`")
                cprint("${bright yellow}note: ${default yellow}or `xmake&&xmake install` in cmd on Windows with Administrator permission")
                raise(errors)
            end
        }
    }
end
