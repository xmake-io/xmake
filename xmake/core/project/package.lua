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
-- @file        package.lua
--

-- define module
local package = {}
local _instance = _instance or {}

-- load modules
local io            = require("base/io")
local os            = require("base/os")
local path          = require("base/path")
local table         = require("base/table")
local utils         = require("base/utils")
local semver        = require("base/semver")
local rule          = require("project/rule")
local config        = require("project/config")
local sandbox       = require("sandbox/sandbox")
local localcache    = require("cache/localcache")
local instance_deps = require("base/private/instance_deps")

-- save the requires info to the cache
function _instance:save()
    package._cache():set(self:name(), self._INFO)
    package._cache():save()
end

-- clear the package
function _instance:clear()
    local info = self._INFO
    if info then
        for k, v in pairs(info) do
            if not k:startswith("__") then
                info[k] = nil
            end
        end
    end
    self._COMPONENT_DEPS = nil
end

-- dump this package
function _instance:dump()
    utils.dump(self._INFO)
end

-- get the require info
function _instance:get(infoname)
    return self._INFO[infoname]
end

-- get the package name (with alias name)
function _instance:name()
    return self._NAME
end

-- get the package version
function _instance:version()

    -- get it from cache first
    if self._VERSION ~= nil then
        return self._VERSION
    end

    -- get version
    local version = nil
    local verstr = self:get("version")
    if verstr then
        version = semver.new(verstr)
    end
    self._VERSION = version or false
    return version
end

-- get the package license
function _instance:license()
    return self:get("license")
end

-- has static libraries?
function _instance:has_static()
    return self:get("static")
end

-- has shared libraries?
function _instance:has_shared()
    return self:get("shared")
end

-- get the require string
function _instance:requirestr()
    return self:get("__requirestr")
end

-- get the require configuration from the given name
--
-- e.g.
--
-- add_requires("xxx", {system = true, configs = {shared = true}})
--
-- local configs = pkg:requireconf()
-- local system = pkg:requireconf("system")
-- local shared = pkg:requireconf("configs", "shared")
--
function _instance:requireconf(name, key)
    local requireconfs = self:get("__requireconfs")
    local value = requireconfs
    if name then
        value = requireconfs and requireconfs[name] or nil
        if value and key then
            value = value[key]
        end
    end
    return value
end

-- get the install directory
-- @see https://github.com/xmake-io/xmake/issues/3106
function _instance:installdir()
    return self:get("installdir")
        or self:get("__installdir") -- deprecated
end

-- get library files
function _instance:libraryfiles()
    return self:get("libfiles")
end

-- get components
function _instance:components()
    return self:get("components")
end

-- get default components
function _instance:components_default()
    return self:get("__components_default")
end

-- get components list with link order
function _instance:components_orderlist()
    return self:get("__components_orderlist")
end

-- get the dependencies of components
function _instance:components_deps()
    return self:get("__components_deps")
end

-- get other extra information from package/on_fetch
--
-- e.g.
--
-- @code
-- package("xxx")
--     on_fetch(function (package)
--         return {includedirs = "", links = "", extra = {foo = ""}}
--     end)
--
-- @endcode
function _instance:extra(name)
    local extra = self:get("extra")
    if extra and name then
        extra = extra[name]
    end
    return extra
end

-- get order dependencies of the given component
function _instance:component_orderdeps(name)
    local component_orderdeps = self._COMPONENT_ORDERDEPS
    if not component_orderdeps then
        component_orderdeps = {}
        self._COMPONENT_ORDERDEPS = component_orderdeps
    end

    -- expand dependencies
    local orderdeps = component_orderdeps[name]
    if not orderdeps then
        orderdeps = table.reverse_unique(self:_sort_componentdeps(name))
        component_orderdeps[name] = orderdeps
    end
    return orderdeps
end

-- set the value to the requires info
function _instance:set(name_or_info, ...)
    if type(name_or_info) == "string" then
        local args = ...
        if args ~= nil then
            self._INFO[name_or_info] = table.unwrap(table.unique(table.join(...)))
        else
            self._INFO[name_or_info] = nil
        end
    elseif table.is_dictionary(name_or_info) then
        for name, info in pairs(table.join(name_or_info, ...)) do
            self:set(name, info)
        end
    end
end

-- add the value to the requires info
function _instance:add(name_or_info, ...)
    if type(name_or_info) == "string" then
        local info = table.wrap(self._INFO[name_or_info])
        self._INFO[name_or_info] = table.unwrap(table.unique(table.join(info, ...)))
    elseif table.is_dictionary(name_or_info) then
        for name, info in pairs(table.join(name_or_info, ...)) do
            self:add(name, info)
        end
    end
end

-- this require info is enabled?
function _instance:enabled()
    return self:get("__enabled")
end

-- enable or disable this require info
function _instance:enable(enabled)
    self:set("__enabled", enabled)
end

-- get the given rule
function _instance:rule(name)
    return self:rules()[name]
end

-- get package rules
-- @see https://github.com/xmake-io/xmake/issues/2374
function _instance:rules()
    local rules = self._RULES
    if rules == nil then
        local ruleinfos = {}
        local installdir = self:installdir()
        local rulesdir = path.join(installdir, "rules")
        if os.isdir(rulesdir) then
            local files = os.match(path.join(rulesdir, "**.lua"))
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
            rulename = "@" .. self:name() .. "/" .. rulename
            local instance = rule.new(rulename, ruleinfo, {package = self})
            if instance:script("load") then
                utils.warning("we cannot add `on_load()` in package rule(%s), please use `on_config()` instead of it!", rulename)
            end
            if instance:script("load_after") then
                utils.warning("we cannot add `after_load()` in package rule(%s), please use `on_config()` instead of it!", rulename)
            end
            rules[rulename] = instance
        end
        self._RULES = rules
    end
    return rules
end

-- sort component deps
function _instance:_sort_componentdeps(name)
    local orderdeps = {}
    local plaindeps = self:components_deps() and self:components_deps()[name]
    for _, dep in ipairs(table.wrap(plaindeps)) do
        table.insert(orderdeps, dep)
        table.join2(orderdeps, self:_sort_componentdeps(dep))
    end
    return orderdeps
end

-- we need sort package set keys by this string
-- @see https://github.com/xmake-io/xmake/pull/2971#issuecomment-1290052169
function _instance:__tostring()
    return "<package: " .. self:name() .. ">"
end

-- get cache
function package._cache()
    return localcache.cache("package")
end

-- load the package from the cache
function package.load(name)
    local info = package._cache():get(name)
    if info == nil then
        return
    end
    return package.load_withinfo(name, info)
end

-- load package from the give package info
function package.load_withinfo(name, info)
    local instance = table.inherit(_instance)
    instance._INFO = info
    instance._NAME = name
    return instance
end

-- return module
return package
