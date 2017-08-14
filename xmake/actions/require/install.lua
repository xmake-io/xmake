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
-- @file        package.lua
--

-- imports
import("core.base.option")
import("core.project.project")
import("action")
import("package")
import("repository")
import("environment")

-- install packages
function main(requires)

    -- enter environment 
    environment.enter()

    -- TODO need optimization
    -- pull all repositories first
    repository.pull()

    -- load packages
    local packages = package.load_packages(requires or project.requires())

    -- download packages
    local waitindex = 0
    local waitchars = {'\\', '|', '/', '-'}
    process.runjobs(function (index)

        local instance = packages[index]
        if instance then

            -- download package
            action.download(instance)
        end

    end, #packages, ifelse(option.get("verbose"), 1, 4), 300, function (indices) 

        -- do not print progress info if be verbose 
        if option.get("verbose") then
            return 
        end
 
        -- update waitchar index
        waitindex = ((waitindex + 1) % #waitchars)

        -- make downloading packages list
        local downloading = {}
        for _, index in ipairs(indices) do
            local instance = packages[index]
            if instance then
                table.insert(downloading, instance:name())
            end
        end
       
        -- trace
        cprintf("\r${yellow}  => ${clear}downloading %s .. %s", table.concat(downloading, ", "), waitchars[waitindex + 1])
    end)

    -- install all required packages from repositories
    for _, instance in ipairs(packages) do
        action.install(instance)
    end

    -- leave environment
    environment.leave()
end

