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
-- @file        rule.lua
--

-- define module
local rule = rule or {}

-- load modules
local os             = require("base/os")
local path           = require("base/path")
local utils          = require("base/utils")
local table          = require("base/table")
local global         = require("base/global")
local interpreter    = require("base/interpreter")
local config         = require("project/config")
local sandbox        = require("sandbox/sandbox")
local sandbox_os     = require("sandbox/modules/os")
local sandbox_module = require("sandbox/modules/import/core/sandbox/module")

-- the directories of rule
function rule._directories()

    -- the directories
    return  {   path.join(global.directory(), "rules")
            ,   path.join(os.programdir(), "rules")
            }
end

-- the interpreter
function rule._interpreter()

    -- the interpreter has been initialized? return it directly
    if rule._INTERPRETER then
        return rule._INTERPRETER
    end

    -- init interpreter
    local interp = interpreter.new()
    assert(interp)
  
    -- define apis
    interp:api_define(rule.apis())

    -- set filter
    interp:filter():register("rule", function (variable)

        -- check
        assert(variable)

        -- attempt to get it directly from the configure
        local result = config.get(variable)
        if not result or type(result) ~= "string" then 

            -- init maps
            local maps = 
            {
                host        = os.host()
            ,   tmpdir      = function () return os.tmpdir() end
            ,   curdir      = function () return os.curdir() end
            ,   scriptdir   = function () return sandbox_os.scriptdir() end
            ,   globaldir   = global.directory()
            ,   configdir   = config.directory()
            ,   projectdir  = os.projectdir()
            ,   programdir  = os.programdir()
            }

            -- map it
            result = maps[variable]
            if type(result) == "function" then
                result = result()
            end
        end 

        -- ok?
        return result
    end)

    -- save interpreter
    rule._INTERPRETER = interp

    -- ok?
    return interp
end

-- load rule
function rule._load(filepath)

    -- get interpreter
    local interp = rule._interpreter()
    assert(interp) 

    -- load rules
    local results, errors = interp:load(filepath, "rule", true, true)
    if not results then
        return nil, errors
    end

    -- make rules
    local rules = {}
    for rulename, ruleinfo in pairs(results) do
        rules[rulename] = rule.new(rulename, ruleinfo)
    end

    -- ok
    return rules
end

-- get rule apis
function rule.apis()

    return 
    {
        values =
        {
            -- rule.set_xxx
            "rule.set_extensions"
            -- rule.add_xxx
        ,   "rule.add_imports"
        }
    ,   script =
        {
            -- rule.on_xxx
            "rule.on_build"
        ,   "rule.on_clean"
        ,   "rule.on_package"
        ,   "rule.on_install"
        ,   "rule.on_uninstall"
        ,   "rule.on_build_all"
        ,   "rule.on_clean_all"
        ,   "rule.on_package_all"
        ,   "rule.on_install_all"
        ,   "rule.on_uninstall_all"
        }
    }
end

-- new a rule instance
function rule.new(name, info)

    -- init a rule instance
    local instance = table.inherit(rule)
    assert(instance)

    -- save name and info
    instance._NAME = name
    instance._INFO = info

    -- ok?
    return instance
end

-- get the rule info
function rule:get(name)
    return self._INFO[name]
end

-- get the rule name
function rule:name()
    return self._NAME
end

-- build source files
function rule:build(target, sourcefiles)

    -- build all?
    local build_all = self:script("build_all")
    if build_all then
        return sandbox.load(build_all, target, sourcefiles)
    else
        local build = self:script("build")
        if not build then
            return false, string.format("rule(%s): build script not found!", self:name())
        end
        for _, sourcefile in ipairs(table.wrap(sourcefiles)) do
            local ok, errors = sandbox.load(build, target, sourcefile)
            if not ok then
                return false, errors
            end
        end
    end

    -- ok
    return true
end

-- clean files
function rule:clean(target, sourcefiles)

    -- clean all?
    local clean_all = self:script("clean_all")
    if clean_all then
        return sandbox.load(clean_all, target, sourcefiles)
    else
        local clean = self:script("clean")
        if clean then
            for _, sourcefile in ipairs(table.wrap(sourcefiles)) do
                local ok, errors = sandbox.load(clean, target, sourcefile)
                if not ok then
                    return false, errors
                end
            end
        end
    end

    -- ok
    return true
end

-- install files
function rule:install(target, sourcefiles)

    -- install all?
    local install_all = self:script("install_all")
    if install_all then
        return sandbox.load(install_all, target, sourcefiles)
    else
        local install = self:script("install")
        if install then
            for _, sourcefile in ipairs(table.wrap(sourcefiles)) do
                local ok, errors = sandbox.load(install, target, sourcefile)
                if not ok then
                    return false, errors
                end
            end
        end
    end

    -- ok
    return true
end

-- uninstall files
function rule:uninstall(target, sourcefiles)

    -- uninstall all?
    local uninstall_all = self:script("uninstall_all")
    if uninstall_all then
        return sandbox.load(uninstall_all, target, sourcefiles)
    else
        local uninstall = self:script("uninstall")
        if uninstall then
            for _, sourcefile in ipairs(table.wrap(sourcefiles)) do
                local ok, errors = sandbox.load(uninstall, target, sourcefile)
                if not ok then
                    return false, errors
                end
            end
        end
    end

    -- ok
    return true
end

-- package files
function rule:package(target, sourcefiles)

    -- package all?
    local package_all = self:script("package_all")
    if package_all then
        return sandbox.load(package_all, target, sourcefiles)
    else
        local package = self:script("package")
        if package then
            for _, sourcefile in ipairs(table.wrap(sourcefiles)) do
                local ok, errors = sandbox.load(package, target, sourcefile)
                if not ok then
                    return false, errors
                end
            end
        end
    end

    -- ok
    return true
end

-- get xxx_script
function rule:script(name, generic)

    -- get script
    local script = self:get(name)
    local result = nil
    if type(script) == "function" then
        result = script
    elseif type(script) == "table" then

        -- match script for special plat and arch
        local plat = (config.get("plat") or "")
        local pattern = plat .. '|' .. (config.get("arch") or "")
        for _pattern, _script in pairs(script) do
            if not _pattern:startswith("__") and pattern:find('^' .. _pattern .. '$') then
                result = _script
                break
            end
        end

        -- match script for special plat
        if result == nil then
            for _pattern, _script in pairs(script) do
                if not _pattern:startswith("__") and plat:find('^' .. _pattern .. '$') then
                    result = _script
                    break
                end
            end
        end

        -- get generic script
        result = result or script["__generic__"] or generic
    end

    -- only generic script
    result = result or generic

    -- imports some modules first
    if result and result ~= generic then
        local scope = getfenv(result)
        if scope then
            for _, modulename in ipairs(table.wrap(self:get("imports"))) do
                scope[sandbox_module.name(modulename)] = sandbox_module.import(modulename, {anonymous = true})
            end
        end
    end

    -- ok
    return result
end

-- get the given global rule
function rule.rule(name)
    return rule.rules()[name]
end

-- get global rules
function rule.rules()
 
    -- return it directly if exists
    if rule._RULES then
        return rule._RULES 
    end

    -- load rules
    local rules = {}
    local dirs = rule._directories()
    for _, dir in ipairs(dirs) do

        -- get files
        local files = os.match(path.join(dir, "**/xmake.lua"))
        if files then
            for _, filepath in ipairs(files) do

                -- load rule
                local results, errors = rule._load(filepath)

                -- save rule
                if results then
                    table.join2(rules, results)
                else
                    os.raise(errors)
                end
            end
        end
    end

    -- make rule instances
    local instances = {}
    for rulename, ruleinfo in pairs(rules) do
        instances[rulename] = rule.new(rulename, ruleinfo)
    end

    -- save it
    rule._RULES = instances

    -- ok?
    return rule._RULES
end

-- return module
return rule
