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
-- Copyright (C) 2015-present, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        rule.lua
--

-- define module
local rule = rule or {}
local _instance = _instance or {}

-- load modules
local os             = require("base/os")
local path           = require("base/path")
local utils          = require("base/utils")
local table          = require("base/table")
local global         = require("base/global")
local interpreter    = require("base/interpreter")
local instance_deps  = require("base/private/instance_deps")
local config         = require("project/config")
local sandbox        = require("sandbox/sandbox")
local sandbox_os     = require("sandbox/modules/os")
local sandbox_module = require("sandbox/modules/import/core/sandbox/module")

-- get package
function _instance:_package()
    return self._PACKAGE
end

-- invalidate the previous cache
function _instance:_invalidate(name)
    if name == "deps" then
        self._DEPS = nil
        self._ORDERDEPS = nil
    end
end

-- build deps
function _instance:_build_deps()
    local instances = table.clone(rule.rules())
    if rule._project() then
        table.join2(instances, rule._project().rules())
    end
    if self:_package() then
        table.join2(instances, self:_package():rules())
    end
    self._DEPS      = self._DEPS or {}
    self._ORDERDEPS = self._ORDERDEPS or {}
    instance_deps.load_deps(self, instances, self._DEPS, self._ORDERDEPS, {self:name()})
end

-- clone rule
function _instance:clone()
    local instance = rule.new(self:name(), self._INFO:clone())
    instance._DEPS = self._DEPS
    instance._ORDERDEPS = self._ORDERDEPS
    instance._PACKAGE = self._PACKAGE
    return instance
end

-- get the rule info
function _instance:get(name)
    return self._INFO:get(name)
end

-- set the value to the rule info
function _instance:set(name, ...)
    self._INFO:apival_set(name, ...)
    self:_invalidate(name)
end

-- add the value to the rule info
function _instance:add(name, ...)
    self._INFO:apival_add(name, ...)
    self:_invalidate(name)
end

-- get the extra configuration
function _instance:extraconf(name, item, key)
    return self._INFO:extraconf(name, item, key)
end

-- set the extra configuration
function _instance:extraconf_set(name, item, key, value)
    return self._INFO:extraconf_set(name, item, key, value)
end

-- get the rule name
function _instance:name()
    return self._NAME
end

-- set the rule name
function _instance:name_set(name)
    self._NAME = name
end

-- get the rule kind
--
-- current supported kind:
--  - target: default, only for each target
--  - project: global rule, for whole project
--
function _instance:kind()
    return self:get("kind") or "target"
end

-- get the given dependent rule
function _instance:dep(name)
    local deps = self:deps()
    if deps then
        return deps[name]
    end
end

-- get rule deps
function _instance:deps()
    if self._DEPS == nil then
        self:_build_deps()
    end
    return self._DEPS
end

-- get rule order deps
function _instance:orderdeps()
    if self._DEPS == nil then
        self:_build_deps()
    end
    return self._ORDERDEPS
end

-- get xxx_script
function _instance:script(name, generic)

    -- get script
    local script = self:get(name)
    local result = nil
    if type(script) == "function" then
        result = script
    elseif type(script) == "table" then

        -- get plat and arch
        local plat = config.get("plat") or ""
        local arch = config.get("arch") or ""

        -- match pattern
        --
        -- `@linux`
        -- `@linux|x86_64`
        -- `@macosx,linux`
        -- `android@macosx,linux`
        -- `android|armeabi-v7a@macosx,linux`
        -- `android|armeabi-v7a@macosx,linux|x86_64`
        -- `android|armeabi-v7a@linux|x86_64`
        --
        for _pattern, _script in pairs(script) do
            local hosts = {}
            local hosts_spec = false
            _pattern = _pattern:gsub("@(.+)", function (v)
                for _, host in ipairs(v:split(',')) do
                    hosts[host] = true
                    hosts_spec = true
                end
                return ""
            end)
            if not _pattern:startswith("__") and (not hosts_spec or hosts[os.subhost() .. '|' .. os.subarch()] or hosts[os.subhost()])
            and (_pattern:trim() == "" or (plat .. '|' .. arch):find('^' .. _pattern .. '$') or plat:find('^' .. _pattern .. '$')) then
                result = _script
                break
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
    return result
end

-- the directories of rule
function rule._directories()
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
    return interp
end

-- get project
function rule._project()
    return rule._PROJECT
end

-- load rule
function rule._load(filepath)

    -- get interpreter
    local interp = rule._interpreter()
    assert(interp)

    -- load script
    local ok, errors = interp:load(filepath)
    if not ok then
        return nil, errors
    end

    -- load rules
    local results, errors = interp:make("rule", true, true)
    if not results then
        return nil, errors
    end
    return results
end

-- get rule apis
function rule.apis()

    return
    {
        values =
        {
            -- rule.set_xxx
            "rule.set_extensions"
        ,   "rule.set_sourcekinds"
        ,   "rule.set_kind"
            -- rule.add_xxx
        ,   "rule.add_deps"
        ,   "rule.add_imports"
        }
    ,   script =
        {
            -- rule.on_xxx
            "rule.on_run"
        ,   "rule.on_load"
        ,   "rule.on_config"
        ,   "rule.on_link"
        ,   "rule.on_build"
        ,   "rule.on_build_file"
        ,   "rule.on_build_files"
        ,   "rule.on_clean"
        ,   "rule.on_package"
        ,   "rule.on_install"
        ,   "rule.on_uninstall"
        ,   "rule.on_linkcmd"
        ,   "rule.on_buildcmd"
        ,   "rule.on_buildcmd_file"
        ,   "rule.on_buildcmd_files"
            -- rule.before_xxx
        ,   "rule.before_run"
        ,   "rule.before_load"
        ,   "rule.before_link"
        ,   "rule.before_build"
        ,   "rule.before_build_file"
        ,   "rule.before_build_files"
        ,   "rule.before_clean"
        ,   "rule.before_package"
        ,   "rule.before_install"
        ,   "rule.before_uninstall"
        ,   "rule.before_linkcmd"
        ,   "rule.before_buildcmd"
        ,   "rule.before_buildcmd_file"
        ,   "rule.before_buildcmd_files"
            -- rule.after_xxx
        ,   "rule.after_run"
        ,   "rule.after_load"
        ,   "rule.after_link"
        ,   "rule.after_build"
        ,   "rule.after_build_file"
        ,   "rule.after_build_files"
        ,   "rule.after_clean"
        ,   "rule.after_package"
        ,   "rule.after_install"
        ,   "rule.after_uninstall"
        ,   "rule.after_linkcmd"
        ,   "rule.after_buildcmd"
        ,   "rule.after_buildcmd_file"
        ,   "rule.after_buildcmd_files"
        }
    }
end

-- new a rule instance
function rule.new(name, info, opt)
    opt = opt or {}
    local instance = table.inherit(_instance)
    instance._NAME = name
    instance._INFO = info
    instance._PACKAGE = opt.package
    if opt.package then
        -- replace deps in package, @bar -> @zlib/bar
        -- @see https://github.com/xmake-io/xmake/issues/2374
        --
        -- packages/z/zlib/rules/foo.lua
        -- @code
        -- rule("foo")
        --     add_deps("@bar")
        -- @endcode
        --
        -- package/z/zlib/rules/foo.lua
        -- @code
        -- rule("bar")
        --     ...
        -- @endcode
        --
        local deps = {}
        for _, depname in ipairs(table.wrap(instance:get("deps"))) do
            -- @xxx -> @package/xxx
            if depname:startswith("@") and not depname:find("/", 1, true) then
                depname = "@" .. opt.package:name() .. "/" .. depname:sub(2)
            end
            table.insert(deps, depname)
        end
        deps = table.unwrap(deps)
        if deps and #deps > 0 then
            instance:set("deps", deps)
        end
        for depname, extraconf in pairs(table.wrap(instance:extraconf("deps"))) do
            if depname:startswith("@") and not depname:find("/", 1, true) then
                depname = "@" .. opt.package:name() .. "/" .. depname:sub(2)
                instance:extraconf_set("deps", depname, extraconf)
            end
        end
    end
    return instance
end

-- get the given global rule
function rule.rule(name)
    return rule.rules()[name]
end

-- get global rules
function rule.rules()
    local rules = rule._RULES
    if rules == nil then
        local ruleinfos = {}
        local dirs = rule._directories()
        for _, dir in ipairs(dirs) do
            local files = os.files(path.join(dir, "**/xmake.lua"))
            if files then
                for _, filepath in ipairs(files) do
                    local results, errors = rule._load(filepath)
                    if results then
                        table.join2(ruleinfos, results)
                    else
                        os.raise(errors)
                    end
                end
            end
        end

        -- make rule instances
        rules = {}
        for rulename, ruleinfo in pairs(ruleinfos) do
            local instance = rule.new(rulename, ruleinfo)
            rules[rulename] = instance
        end
        rule._RULES = rules
    end
    return rules
end

-- return module
return rule
