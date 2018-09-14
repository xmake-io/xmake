--!A cross-platform build utility based on Lua
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
-- Copyright (C) 2015 - 2018, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        remove.lua
--

-- imports
import("core.base.task")
import("package")
import("repository")
import("environment")
import("lib.detect.cache")

-- show the given package info
function main(requires)

    -- no requires?
    if not requires then
        return 
    end

    -- enter environment 
    environment.enter()

    -- pull all repositories first if not exists
    if not repository.pulled() then
        task.run("repo", {update = true})
    end

    -- clear the detect cache
    cache.clear()

    -- remove all packages
    for _, instance in ipairs(package.load_packages(requires, {nodeps = true})) do
        local requireinfo = instance:requireinfo() or {}
        if os.isdir(instance:directory()) then
            
            -- remove package directory
            os.rm(instance:directory())

            -- trace
            cprint("remove: %s%s ok!", requireinfo.originstr, instance:version_str() and ("/" .. instance:version_str()) or "")
        else
            -- trace
            cprint("remove: %s%s not found!", requireinfo.originstr, instance:version_str() and ("/" .. instance:version_str()) or "")
        end
    end

    -- leave environment
    environment.leave()
end

