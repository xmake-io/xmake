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
import("core.base.task")
import("core.project.config")
import("core.project.project")
import("core.project.cache", {nocache = true})
import("core.platform.platform")
import("builder")

-- main
function main()

    -- get the target name
    local targetname = option.get("target")

    -- config it first
    task.run("config", {target = targetname})

    -- enter cache scope
    cache.enter("local.config")

    -- rebuild?
    local rebuild = false
    if option.get("rebuild") or cache.get("rebuild") then

        -- mark as rebuild
        rebuild = true
        
        -- reset state
        cache.set("rebuild", nil)
    end

    -- flush cache to file
    cache.flush()

    -- enter project directory
    local oldir = os.cd(project.directory())

    -- build it
    try
    {
        function ()

            -- build 
            builder.build(targetname, rebuild) 
        end,

        catch 
        {
            function (errors)

                -- failed
                if errors then
                    raise(errors)
                elseif targetname then
                    raise("build target: %s failed!", targetname)
                else
                    raise("build target failed!")
                end
            end
        }
    }

    -- leave project directory
    os.cd(oldir)

    -- trace
    if rebuild then
        cprint("${bright}build ok!${clear}${ok_hand}")
    end
end
