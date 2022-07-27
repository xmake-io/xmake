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
-- @file        option.lua
--

-- define module
local option    = {}
local _instance = {}

-- load modules
local io             = require("base/io")
local os             = require("base/os")
local path           = require("base/path")
local table          = require("base/table")
local utils          = require("base/utils")
local baseoption     = require("base/option")
local global         = require("base/global")
local scopeinfo      = require("base/scopeinfo")
local interpreter    = require("base/interpreter")
local config         = require("project/config")
local localcache     = require("cache/localcache")
local linker         = require("tool/linker")
local compiler       = require("tool/compiler")
local sandbox        = require("sandbox/sandbox")
local language       = require("language/language")
local sandbox        = require("sandbox/sandbox")
local sandbox_os     = require("sandbox/modules/os")
local sandbox_module = require("sandbox/modules/import/core/sandbox/module")

-- new an instance
function _instance.new(name, info)
    local instance    = table.inherit(_instance)
    instance._NAME    = name
    instance._INFO    = info
    instance._CACHEID = 1
    return instance
end

-- save the option info to the cache
function _instance:_save()

    -- clear scripts for caching to file
    local check = self:get("check")
    local check_after = self:get("check_after")
    local check_before = self:get("check_before")
    self:set("check", nil)
    self:set("check_after", nil)
    self:set("check_before", nil)

    -- save option
    option._cache():set(self:name(), self:info())

    -- restore scripts
    self:set("check", check)
    self:set("check_after", check_after)
    self:set("check_before", check_before)
end

-- clear the option info for cache
function _instance:_clear()
    option._cache():set(self:name(), nil)
end

-- check snippets
function _instance:_do_check_cxsnippets(snippets)

    -- import check_cxsnippets()
    self._check_cxsnippets = self._check_cxsnippets or sandbox_module.import("lib.detect.check_cxsnippets", {anonymous = true})

    -- check for c and c++
    local passed = 0
    local result_output
    for _, kind in ipairs({"c", "cxx"}) do

        -- get conditions
        local links              = self:get("links")
        local snippets           = self:get(kind .. "snippets")
        local types              = self:get(kind .. "types")
        local funcs              = self:get(kind .. "funcs")
        local includes           = self:get(kind .. "includes")

        -- TODO it is deprecated
        local snippet  = self:get(kind .. "snippet")
        if snippet then
            snippets = table.join(snippets or {}, snippet)
        end

        -- need check it?
        if snippets or types or funcs or links or includes then

            -- init source kind
            local sourcekind = kind
            if kind == "c" then
                sourcekind = "cc"
            end

            -- split snippets
            local snippets_build = {}
            local snippets_tryrun = {}
            local snippets_output = {}
            if snippets then
                for name, snippet in pairs(snippets) do
                    if self:extraconf(kind .. "snippets", name, "output") then
                        snippets_output[name] = snippet
                    elseif self:extraconf(kind .. "snippets", name, "tryrun") then
                        snippets_tryrun[name] = snippet
                    else
                        snippets_build[name] = snippet
                    end
                end
                if #table.keys(snippets_output) > 1 then
                    return false, -1, string.format("option(%s): only support for only one snippet with output!", self:name())
                end
            end

            -- check snippets (run with output)
            if #table.keys(snippets_output) > 0 then
                local ok, results_or_errors, output = sandbox.load(self._check_cxsnippets, snippets_output, {
                                                            target = self,
                                                            sourcekind = sourcekind,
                                                            types = types,
                                                            funcs = funcs,
                                                            includes = includes,
                                                            tryrun = true, output = true})
                if not ok then
                    return false, -1, results_or_errors
                end

                -- passed or no passed?
                if results_or_errors then
                    passed = 1
                    result_output = output
                else
                    passed = -1
                    break
                end
            end

            -- check snippets (run only)
            if passed == 0 and #table.keys(snippets_tryrun) > 0 then
                local ok, results_or_errors = sandbox.load(self._check_cxsnippets, snippets_tryrun, {
                                                            target = self,
                                                            sourcekind = sourcekind,
                                                            types = types,
                                                            funcs = funcs,
                                                            includes = includes,
                                                            tryrun = true})
                if not ok then
                    return false, -1, results_or_errors
                end

                -- passed or no passed?
                if results_or_errors then
                    passed = 1
                else
                    passed = -1
                    break
                end
            end

            -- check snippets (build only)
            if passed == 0 or #table.keys(snippets_build) > 0 then
                local ok, results_or_errors = sandbox.load(self._check_cxsnippets, snippets_build, {
                                                            target = self,
                                                            sourcekind = sourcekind,
                                                            types = types,
                                                            funcs = funcs,
                                                            includes = includes})
                if not ok then
                    return false, -1, results_or_errors
                end

                -- passed or no passed?
                if results_or_errors then
                    passed = 1
                else
                    passed = -1
                    break
                end
            end
        end
    end
    return true, passed, result_output
end

-- check features
function _instance:_do_check_features()
    local passed = 0
    local features = self:get("features")
    if features then

        -- import core.tool.compiler
        self._core_tool_compiler = self._core_tool_compiler or sandbox_module.import("core.tool.compiler", {anonymous = true})

        -- all features are supported?
        features = table.wrap(features)
        local features_supported = self._core_tool_compiler.has_features(features, {target = self})
        if features_supported and #features_supported == #features then
            passed = 1
        end

        -- trace
        if baseoption.get("verbose") or baseoption.get("diagnosis") then
            for _, feature in ipairs(features) do
                utils.cprint("${dim}checking for feature(%s) ... %s", feature, passed > 0 and "${color.success}${text.success}" or "${color.nothing}${text.nothing}")
            end
        end
    end
    return true, passed
end

-- check option conditions
function _instance:_do_check()

    -- check snippets
    local ok, passed, errors = self:_do_check_cxsnippets()
    if not ok then
        return false, errors
    end

    -- get snippet output
    local output
    if passed then
        output = errors
    end

    -- check features
    if passed == 0 then
        ok, passed, errors = self:_do_check_features()
        if not ok then
            return false, errors
        end
    end

    -- enable this option if be passed
    if passed > 0 then
        self:enable(true)
        if output then
            self:set_value(output)
        end
    end
    return true
end

-- on check
function _instance:_on_check()

    -- get check script
    local check = self:script("check")
    if check then
        return sandbox.load(check, self)
    else
        return self:_do_check()
    end
end

-- check option
function _instance:_check()

    -- disable this option first
    self:enable(false)

    -- check it
    local ok, errors = self:_on_check()

    -- get name
    local name = self:name()
    if name:startswith("__") then
        name = name:sub(3)
    end

    -- trace
    local result
    if self:enabled() then
        local value = self:value()
        result = "${color.success}" .. (type(value) == "boolean" and "${text.success}" or tostring(value))
    else
        result = "${color.nothing}${text.nothing}"
    end
    utils.cprint("checking for %s ... %s", name, result)
    if not ok then
        os.raise(errors)
    end

    -- flush io buffer to update progress info
    io.flush()
end

-- invalidate the previous cache key
function _instance:_invalidate()
    self._CACHEID = self._CACHEID + 1
end

-- attempt to check option
function _instance:check()

    -- the option name
    local name = self:name()

    -- get default value, TODO: enable will be deprecated
    local default = self:get("default")
    if default == nil then
        default = self:get("enable")
    end

    -- before and after check
    local check_before = self:script("check_before")
    local check_after  = self:script("check_after")
    if check_before then
        check_before(self)
    end

    -- need check? (only force to check the automatical option without the default value)
    if config.get(name) == nil or default == nil then

        -- use it directly if the default value exists
        if default ~= nil then
            self:set_value(default)
        -- check option as boolean switch automatically if the default value not exists
        elseif default == nil then
            self:_check()
        -- disable this option in other case
        else
            self:enable(false)
        end

    -- need not check? only save this option to configuration directly
    elseif config.get(name) then
        self:_save()
    end

    -- after check
    if check_after then
        check_after(self)
    end
end

-- get the option value
function _instance:value()
    return config.get(self:name())
end

-- set the option value
function _instance:set_value(value)
    config.set(self:name(), value)
    self:_save()
end

-- clear the option status and need recheck it
function _instance:clear()
    config.set(self:name(), nil)
    self:_clear()
end

-- this option is enabled?
function _instance:enabled()
    return config.get(self:name())
end

-- enable or disable this option
--
-- @param enabled   enable option?
-- @param opt       the argument options, e.g. {readonly = true, force = false}
--
function _instance:enable(enabled, opt)

    -- init options
    opt = opt or {}

    -- enable or disable this option?
    if not config.readonly(self:name()) or opt.force then
        config.set(self:name(), enabled, opt)
    end

    -- save or clear this option in cache
    if self:enabled() then
        self:_save()
    else
        self:_clear()
    end
end

-- get the option info
function _instance:info()
    return self._INFO:info()
end

-- get the type: option
function _instance:type()
    return "option"
end

-- get the option info
function _instance:get(name)
    return self._INFO:get(name)
end

-- set the value to the option info
function _instance:set(name, ...)
    self._INFO:apival_set(name, ...)
    self:_invalidate()
end

-- add the value to the option info
function _instance:add(name, ...)
    self._INFO:apival_add(name, ...)
    self:_invalidate()
end

-- remove the value to the option info (deprecated)
function _instance:del(name, ...)
    self._INFO:apival_del(name, ...)
    self:_invalidate()
end

-- remove the value to the option info
function _instance:remove(name, ...)
    self._INFO:apival_remove(name, ...)
    self:_invalidate()
end

-- get the extra configuration
function _instance:extraconf(name, item, key)
    return self._INFO:extraconf(name, item, key)
end

-- get the given dependent option
function _instance:dep(name)
    local deps = self:deps()
    if deps then
        return deps[name]
    end
end

-- get option deps
function _instance:deps()
    return self._DEPS
end

-- get option order deps
function _instance:orderdeps()
    return self._ORDERDEPS
end

-- get the option name
function _instance:name()
    return self._NAME
end

-- get the option description
function _instance:description()
    return self:get("description") or ("The " .. self:name() .. " option")
end

-- get the cache key
function _instance:cachekey()
    return string.format("%s_%d", tostring(self), self._CACHEID)
end

-- get xxx_script
function _instance:script(name)

    -- imports some modules first
    local script = self:get(name)
    if script then
        local scope = getfenv(script)
        if scope then
            for _, modulename in ipairs(table.wrap(self:get("imports"))) do
                scope[sandbox_module.name(modulename)] = sandbox_module.import(modulename, {anonymous = true})
            end
        end
    end
    return script
end

-- show menu?
function _instance:showmenu()
    local showmenu = self:get("showmenu")
    if showmenu == nil then
        -- auto check mode? we hidden menu by default
        if self:get("ctypes") or self:get("cxxtypes") or
            self:get("cfuncs") or self:get("cxxfuncs") or
            self:get("cincludes") or self:get("cxxincludes") or
            self:get("links") or self:get("syslinks") or
            self:get("csnippets") or self:get("cxxsnippets") or
            self:get("features") then
            showmenu = false
        end
    end
    return showmenu
end

-- get cache
function option._cache()
    return localcache.cache("option")
end

-- get option apis
function option.apis()

    return
    {
        values =
        {
            -- option.set_xxx
            "option.set_values"
        ,   "option.set_default"
        ,   "option.set_showmenu"
        ,   "option.set_category"
        ,   "option.set_warnings"
        ,   "option.set_optimize"
        ,   "option.set_languages"
        ,   "option.set_description"
            -- option.add_xxx
        ,   "option.add_deps"
        ,   "option.add_imports"
        ,   "option.add_vectorexts"
        ,   "option.add_features"
        }
    ,   keyvalues =
        {
            -- option.set_xxx
            "option.set_configvar"
        }
    ,   script =
        {
            -- option.before_xxx
            "option.before_check"
            -- option.on_xxx
        ,   "option.on_check"
            -- option.after_xxx
        ,   "option.after_check"
        }
    }
end

-- get interpreter
function option.interpreter()

    -- the interpreter has been initialized? return it directly
    if option._INTERPRETER then
        return option._INTERPRETER
    end

    -- init interpreter
    local interp = interpreter.new()

    -- define apis for option
    interp:api_define(option.apis())

    -- define apis for language
    interp:api_define(language.apis())

    -- we need to be able to precisely control the direction of deduplication of different types of values.
    -- the default is to de-duplicate from left to right, but like links/syslinks need to be de-duplicated from right to left.
    --
    -- @see https://github.com/xmake-io/xmake/issues/1903
    --
    interp:deduplication_policy_set("links", "toleft")
    interp:deduplication_policy_set("syslinks", "toleft")
    interp:deduplication_policy_set("frameworks", "toleft")

    -- register filter handler
    interp:filter():register("option", function (variable)

        -- init maps
        local maps =
        {
            arch       = function() return config.get("arch") or os.arch() end
        ,   plat       = function() return config.get("plat") or os.host() end
        ,   mode       = function() return config.get("mode") or "release" end
        ,   host       = os.host()
        ,   subhost    = os.subhost()
        ,   scriptdir  = function () return interp:pending() and interp:scriptdir() or sandbox_os.scriptdir() end
        ,   globaldir  = global.directory()
        ,   configdir  = config.directory()
        ,   projectdir = os.projectdir()
        ,   programdir = os.programdir()
        }

        -- map it
        local result = maps[variable]
        if type(result) == "function" then
            result = result()
        end
        return result
    end)

    -- save interpreter
    option._INTERPRETER = interp

    -- ok?
    return interp
end

-- new an option instance
function option.new(name, info)
    return _instance.new(name, info)
end

-- load the option info from the cache
function option.load(name)

    -- check
    assert(name)

    -- get info
    local info = option._cache():get(name)
    if info == nil then
        return
    end
    return option.new(name, scopeinfo.new("option", info))
end

-- save all options to the cache file
function option.save()
    option._cache():save()
end

-- return module
return option
