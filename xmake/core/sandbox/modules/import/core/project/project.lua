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
-- Copyright (C) 2015-2020, TBOOX Open Source Group.
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
local import      = require("sandbox/modules/import")

-- export some readonly interfaces
sandbox_core_project.get          = project.get
sandbox_core_project.rule         = project.rule
sandbox_core_project.rules        = project.rules
sandbox_core_project.toolchain    = project.toolchain
sandbox_core_project.toolchains   = project.toolchains
sandbox_core_project.target       = project.target
sandbox_core_project.targets      = project.targets
sandbox_core_project.ordertargets = project.ordertargets
sandbox_core_project.option       = project.option
sandbox_core_project.options      = project.options
sandbox_core_project.rootfile     = project.rootfile
sandbox_core_project.allfiles     = project.allfiles
sandbox_core_project.rcfile       = project.rcfile
sandbox_core_project.directory    = project.directory
sandbox_core_project.clear        = project.clear
sandbox_core_project.name         = project.name
sandbox_core_project.modes        = project.modes
sandbox_core_project.mtimes       = project.mtimes
sandbox_core_project.version      = project.version
sandbox_core_project.require      = project.require
sandbox_core_project.requires     = project.requires
sandbox_core_project.requires_str = project.requires_str
sandbox_core_project.policy       = project.policy
sandbox_core_project.tmpdir       = project.tmpdir
sandbox_core_project.tmpfile      = project.tmpfile

-- load project
function sandbox_core_project.load()
    deprecated.add("project.clear() or only remove it", "project.load()")
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
    local jobs = baseoption.get("jobs") or math.ceil(os.cpuinfo().ncpu * 3 / 2)
    import("private.async.runjobs", {anonymous = true})("check_options", instance:fork(checktask):script(), {total = #options, comax = jobs})

    -- save all options to the cache file
    option.save()

    -- check toolchains configuration for all target in the current project
    -- @note we must check targets after loading options
    for _, target in pairs(table.wrap(targets)) do
        if target:get("enabled") ~= false and (target:get("toolchains") or target:plat() ~= config.get("plat")) then
            for _, toolchain_inst in pairs(target:toolchains()) do
                -- check toolchains for `target/set_toolchains()`
                if target:get("toolchains") then
                    if not toolchain_inst:check() then
                        raise("toolchain(\"%s\"): not found!", toolchain_inst:name())
                    end
                else
                    -- check platform toolchains for `target/set_plat()`
                    local ok, errors = target:platform():check()
                    if not ok then
                        raise(errors)
                    end
                end
            end
        end
    end

    -- leave the project directory
    local ok, errors = os.cd(oldir)
    if not ok then
        raise(errors)
    end
end

-- get the filelock of the whole project directory
function sandbox_core_project.filelock()
    local filelock, errors = project.filelock()
    if not filelock then
        raise("cannot create the project lock, %s!", errors or "unknown errors")
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

-- return module
return sandbox_core_project
