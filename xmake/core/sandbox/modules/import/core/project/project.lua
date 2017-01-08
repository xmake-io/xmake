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
-- @file        project.lua
--

-- define module
local sandbox_core_project = sandbox_core_project or {}

-- load modules
local table     = require("base/table")
local config    = require("project/config")
local project   = require("project/project")
local raise     = require("sandbox/modules/raise")

-- load project
function sandbox_core_project.load()

    -- load it
    local ok, errors = project.load()
    if not ok then
        raise(errors)
    end
end

-- check project options
function sandbox_core_project.check()

    -- check it
    local ok, errors = project.check()
    if not ok then
        raise(errors)
    end
end

-- get the given target
function sandbox_core_project.target(targetname)

    -- get it
    return project.target(targetname)
end

-- get the all targets
function sandbox_core_project.targets()

    -- get targets
    local targets = project.targets()
    assert(targets)

    -- ok
    return targets
end

-- get the project file
function sandbox_core_project.file()

    -- get it
    return xmake._PROJECT_FILE
end

-- get the project directory
function sandbox_core_project.directory()

    -- get it
    return xmake._PROJECT_DIR
end

-- get the project mtimes
function sandbox_core_project.mtimes()

    -- get it
    return project.mtimes()
end

-- get the project version
function sandbox_core_project.version()
  
    -- get version
    for _, target in pairs(table.wrap(project.targets())) do
        local version = target:get("version")
        if version then
            return version
        end
    end
end

-- get the project name
function sandbox_core_project.name()
  
    -- get version
    for _, target in pairs(table.wrap(project.targets())) do
        local name = target:get("project")
        if name then
            return name
        end
    end

    -- uses the project directory name
    return path.basename(project.directory())
end

-- return module
return sandbox_core_project
