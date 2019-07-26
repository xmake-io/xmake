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
-- Copyright (C) 2015 - 2019, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        project.lua
--

-- define module
local sandbox_core_project = sandbox_core_project or {}

-- load modules
local table       = require("base/table")
local deprecated  = require("base/deprecated")
local utils       = require("base/utils")
local baseoption  = require("base/option")
local config      = require("project/config")
local option      = require("project/option")
local project     = require("project/project")
local sandbox     = require("sandbox/sandbox")
local raise       = require("sandbox/modules/raise")
local environment = require("platform/environment")
local package     = require("package/package")

-- load project
function sandbox_core_project.load()
    -- deprecated
    deprecated.add("project.clear() or only remove it", "project.load()")
end

-- clear project
function sandbox_core_project.clear()
    project.clear()
end

-- check project options
function sandbox_core_project.check()

    -- get project options
    local options = {}
    for _, opt in pairs(project.options()) do
        table.insert(options, opt)
    end

    -- get sandbox instance
    local instance = sandbox.instance()
    assert(instance)

    -- enter the project directory
    local oldir, errors = os.cd(os.projectdir())
    if not oldir then
        raise(errors)
    end

    -- enter toolchains environment
    environment.enter("toolchains")

    -- init check task
    local checked   = {}
    local checktask = function (index) 

        -- get option
        local opt = options[index]
        if opt then

            -- check deps of this option first
            for depname, dep in pairs(opt:deps()) do
                if not checked[depname] then
                    dep:check()
                    checked[depname] = true
                end
            end

            -- check this option
            if not checked[opt:name()] then
                opt:check() 
                checked[opt:name()] = true
            end
        end
    end

    -- check all options
    local ok, errors = process.runjobs(instance:fork(checktask):script(), #options, 4)
    if not ok then
        raise(errors)
    end

    -- leave toolchains environment
    environment.leave("toolchains")

    -- save all options to the cache file
    option.save()

    -- leave the project directory
    ok, errors = os.cd(oldir)
    if not ok then
        raise(errors)
    end
end

-- get the given project rule
function sandbox_core_project.rule(name)
    return project.rule(name)
end

-- get the all project rules
function sandbox_core_project.rules()
    return project.rules()
end

-- get the given target
function sandbox_core_project.target(name)
    return project.target(name)
end

-- get the all targets
function sandbox_core_project.targets()
    return project.targets()
end

-- get the given option
function sandbox_core_project.option(name)
    return project.option(name)
end

-- get the all options
function sandbox_core_project.options()
    return project.options()
end

-- get the project file
function sandbox_core_project.file()
    return project.file()
end

-- get the project directory
function sandbox_core_project.directory()
    return project.directory()
end

-- get the filelock of the whole project directory
function sandbox_core_project.filelock()
    local filelock = project.filelock()
    if not filelock then
        raise("cannot create the project lock!")
    end
    return filelock
end

-- lock the whole project 
function sandbox_core_project.lock(opt)
    if sandbox_core_project.trylock(opt) then
        return true
    elseif baseoption.get("diagnosis") then
        utils.warning("the current project is being accessed by other processes, please waiting!") 
    end
    local ok, errors = sandbox_core_project.filelock():lock(opt)
    if not ok then
        raise(errors)
    end
end

-- trylock the whole project 
function sandbox_core_project.trylock(opt)
    return sandbox_core_project.filelock():trylock(opt)
end

-- unlock the whole project 
function sandbox_core_project.unlock()
    local ok, errors = sandbox_core_project.filelock():unlock()
    if not ok then
        raise(errors)
    end
end

-- get the project mtimes
function sandbox_core_project.mtimes()
    return project.mtimes()
end

-- get the project info from the given name
function sandbox_core_project.get(name)
    return project.get(name)
end

-- get the project name
function sandbox_core_project.name()
    return project.get("project")
end

-- get the project version, the root version of the target scope
function sandbox_core_project.version()
    return project.get("target.version")
end

-- get the project modes
function sandbox_core_project.modes()
    local modes = project.get("modes") or {}
    for _, target in pairs(table.wrap(project.targets())) do
        for _, rule in ipairs(target:orderules()) do
            local name = rule:name()
            if name:startswith("mode.") then
                table.insert(modes, name:sub(6))
            end
        end
    end
    return table.unique(modes)
end

-- get the the given require info
function sandbox_core_project.require(name)
    return project.require(name)
end

-- get the all requires
function sandbox_core_project.requires()
    return project.requires()
end

-- get the all raw string requires
function sandbox_core_project.requires_str()
    return project.requires_str()
end

-- return module
return sandbox_core_project
