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

    -- ok
    return results
end

-- load deps 
--
-- .e.g 
--
-- a.deps = b
-- b.deps = c
--
-- orderdeps: c -> b -> a
--
function rule._load_deps(self, rules, deps, orderdeps)

    -- get dep rules
    for _, dep in ipairs(table.wrap(self:get("deps"))) do
        local deprule = rules[dep]
        if deprule then
            rule._load_deps(deprule, rules, deps, orderdeps)
            if not deps[dep] then
                deps[dep] = deprule
                table.insert(orderdeps, deprule)
            end
        end
    end
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
        ,   "rule.add_deps"
        ,   "rule.add_imports"
        }
    ,   script =
        {
            -- rule.on_xxx
            "rule.on_run"
        ,   "rule.on_load"
        ,   "rule.on_build"
        ,   "rule.on_build_file"
        ,   "rule.on_build_files"
        ,   "rule.on_clean"
        ,   "rule.on_package"
        ,   "rule.on_install"
        ,   "rule.on_uninstall"
            -- rule.before_xxx
        ,   "rule.before_run"
        ,   "rule.before_load"
        ,   "rule.before_build"
        ,   "rule.before_build_file"
        ,   "rule.before_build_files"
        ,   "rule.before_clean"
        ,   "rule.before_package"
        ,   "rule.before_install"
        ,   "rule.before_uninstall"
            -- rule.after_xxx
        ,   "rule.after_run"
        ,   "rule.after_load"
        ,   "rule.after_build"
        ,   "rule.after_build_file"
        ,   "rule.after_build_files"
        ,   "rule.after_clean"
        ,   "rule.after_package"
        ,   "rule.after_install"
        ,   "rule.after_uninstall"
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

-- get the given dependent rule
function rule:dep(name)
    local deps = self:deps()
    if deps then
        return deps[name]
    end
end

-- get rule deps
function rule:deps()
    return self._DEPS
end

-- get rule order deps
function rule:orderdeps()
    return self._ORDERDEPS
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
        local instance = rule.new(rulename, ruleinfo)
        instances[rulename] = instance
    end

    -- load rule deps
    for _, instance in pairs(instances)  do
        instance._DEPS      = instance._DEPS or {}
        instance._ORDERDEPS = instance._ORDERDEPS or {}
        rule._load_deps(instance, instances, instance._DEPS, instance._ORDERDEPS)
    end

    -- save it
    rule._RULES = instances

    -- ok?
    return rule._RULES
end

-- return module
return rule
