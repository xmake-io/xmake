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
-- @file        target.lua
--

-- define module
local target    = target or {}
local _instance = _instance or {}

-- load modules
local bit             = require("base/bit")
local os              = require("base/os")
local path            = require("base/path")
local hash            = require("base/hash")
local utils           = require("base/utils")
local table           = require("base/table")
local baseoption      = require("base/option")
local hashset         = require("base/hashset")
local deprecated      = require("base/deprecated")
local select_script   = require("base/private/select_script")
local match_copyfiles = require("base/private/match_copyfiles")
local instance_deps   = require("base/private/instance_deps")
local is_cross        = require("base/private/is_cross")
local memcache        = require("cache/memcache")
local rule            = require("project/rule")
local option          = require("project/option")
local config          = require("project/config")
local policy          = require("project/policy")
local project_package = require("project/package")
local tool            = require("tool/tool")
local linker          = require("tool/linker")
local compiler        = require("tool/compiler")
local toolchain       = require("tool/toolchain")
local platform        = require("platform/platform")
local environment     = require("platform/environment")
local language        = require("language/language")
local sandbox         = require("sandbox/sandbox")
local sandbox_module  = require("sandbox/modules/import/core/sandbox/module")

-- new a target instance
function _instance.new(name, info)
    local instance     = table.inherit(_instance)
    instance._INFO     = info
    instance._CACHEID  = 1
    if name then
        instance:name_set(name)
    end
    return instance
end

-- get memcache
function _instance:_memcache()
    local cache = self._MEMCACHE
    if not cache then
        cache = memcache.cache("core.project.target." .. tostring(self))
        self._MEMCACHE = cache
    end
    return cache
end

-- load rule, move cache to target
function _instance:_load_rule(ruleinst, suffix)

    -- init cache
    local key = ruleinst:fullname() .. (suffix and ("_" .. suffix) or "")
    local cache = self._RULES_LOADED or {}

    -- do load
    if cache[key] == nil then
        local on_load = ruleinst:script("load" .. (suffix and ("_" .. suffix) or ""))
        if on_load then
            local ok, errors = sandbox.load(on_load, self)
            cache[key] = {ok, errors}
        else
            cache[key] = {true}
        end

        -- before_load has been deprecated
        if on_load and suffix == "before" then
            deprecated.add(ruleinst:fullname() .. ".on_load", ruleinst:fullname() .. ".before_load")
        end
    end

    -- save cache
    self._RULES_LOADED = cache

    -- return results
    local results = cache[key]
    if results then
        return results[1], results[2]
    end
end

-- load rules
function _instance:_load_rules(suffix)
    for _, r in ipairs(self:orderules()) do
        local ok, errors = self:_load_rule(r, suffix)
        if not ok then
            return false, errors
        end
    end
    return true
end

-- do load target and rules
function _instance:_load()

    -- do load with target rules
    local ok, errors = self:_load_rules()
    if not ok then
        return false, errors
    end

    -- do load for target
    local on_load = self:script("load")
    if on_load then
        ok, errors = sandbox.load(on_load, self)
        if not ok then
            return false, errors
        end
    end

    -- mark as loaded
    self._LOADED = true
    return true
end

-- do before_load for rules
-- @note it's deprecated, please use on_load instead of before_load
function _instance:_load_before()
    local ok, errors = self:_load_rules("before")
    if not ok then
        return false, errors
    end
    return true
end

-- do after_load target and rules
function _instance:_load_after()

    -- enter the environments of the target packages
    local oldenvs = os.addenvs(self:pkgenvs())

    -- do load for target
    local after_load = self:script("load_after")
    if after_load then
        local ok, errors = sandbox.load(after_load, self)
        if not ok then
            return false, errors
        end
    end

    -- do after_load with target rules
    local ok, errors = self:_load_rules("after")
    if not ok then
        return false, errors
    end

    -- leave the environments of the target packages
    os.setenvs(oldenvs)
    self._LOADED_AFTER = true
    return true
end

-- get the visibility, private: 1, interface: 2, public: 3 = 1 | 2
function _instance:_visibility(opt)
    local visibility = 1
    if opt then
        if opt.interface then
            visibility = 2
        elseif opt.public then
            visibility = 3
        end
    end
    return visibility
end

-- update file rules
--
-- if we add files in on_load() dynamically, we need to update file rules,
-- otherwise it will cause: unknown source file: ...
--
function _instance:_update_filerules()
    local rulenames = {}
    local extensions = {}
    for _, sourcefile in ipairs(table.wrap(self:get("files"))) do
        local extension = path.extension((sourcefile:gsub("|.*$", "")))
        if not extensions[extension] then
            local lang = language.load_ex(extension)
            if lang and lang:rules() then
                table.join2(rulenames, lang:rules())
            end
            extensions[extension] = true
        end
    end
    rulenames = table.unique(rulenames)
    for _, rulename in ipairs(rulenames) do
        local r = target._project() and target._project().rule(rulename, {namespace = self:namespace()}) or rule.rule(rulename)
        if r then
            -- only add target rules
            if r:kind() == "target" then
                if not self:rule(rulename) then
                    self:rule_add(r)
                    for _, deprule in ipairs(r:orderdeps()) do
                        if not self:rule(deprule:name()) then
                            self:rule_add(deprule)
                        end
                    end
                end
            end
        end
    end
end

-- invalidate the previous cache
function _instance:_invalidate(name)
    self._CACHEID = self._CACHEID + 1
    self._POLICIES = nil
    self:_memcache():clear()
    -- we need to flush the source files cache if target/files are modified, e.g. `target:add("files", "xxx.c")`
    if name == "files" then
        self._SOURCEFILES = nil
        self._OBJECTFILES = nil
        self._SOURCEBATCHES = nil
        self:_update_filerules()
    elseif name == "deps" then
        self._DEPS = nil
        self._ORDERDEPS = nil
        self._INHERITDEPS = nil
    end
    if self._FILESCONFIG then
        self._FILESCONFIG[name] = nil
    end
end

-- build deps
function _instance:_build_deps()
    if target._project() then
        local instances   = target._project().targets()
        self._DEPS        = self._DEPS or {}
        self._ORDERDEPS   = self._ORDERDEPS or {}
        self._INHERITDEPS = self._INHERITDEPS or {}
        instance_deps.load_deps(self, instances, self._DEPS, self._ORDERDEPS, {self:fullname()})
        -- @see https://github.com/xmake-io/xmake/issues/4689
        instance_deps.load_deps(self, instances, {}, self._INHERITDEPS, {self:fullname()}, function (t, dep)
            local depinherit = t:extraconf("deps", dep:name(), "inherit")
            if depinherit == nil then
                depinherit = t:extraconf("deps", dep:fullname(), "inherit")
            end
            return depinherit == nil or depinherit
        end)
    end
end

-- is loaded?
function _instance:_is_loaded()
    return self._LOADED
end

-- get values from target deps with {interface|public = ...}
function _instance:_get_from_deps(name, result_values, result_sources, opt)
    local orderdeps = self:orderdeps({inherit = true})
    local total = #orderdeps
    for idx, _ in ipairs(orderdeps) do
        local dep = orderdeps[total + 1 - idx]
        local values = dep:get(name, opt)
        if values ~= nil then
            table.insert(result_values, values)
            table.insert(result_sources, "dep::" .. dep:name())
        end
        local dep_values = {}
        local dep_sources = {}
        dep:_get_from_options(name, dep_values, dep_sources, opt)
        dep:_get_from_packages(name, dep_values, dep_sources, opt)
        for idx, values in ipairs(dep_values) do
            local dep_source = dep_sources[idx]
            table.insert(result_values, values)
            table.insert(result_sources, "dep::" .. dep:name() .. "/" .. dep_source)
        end
    end
end

-- get values from target options with {interface|public = ...}
function _instance:_get_from_options(name, result_values, result_sources, opt)
    for _, opt_ in ipairs(self:orderopts(opt)) do
        local values = opt_:get(name)
        if values ~= nil then
            table.insert(result_values, values)
            table.insert(result_sources, "option::" .. opt_:name())
        end
    end
end

-- get values from target packages with {interface|public = ...}
function _instance:_get_from_packages(name, result_values, result_sources, opt)
    local function _filter_libfiles(libfiles)
        local result = {}
        for _, libfile in ipairs(table.wrap(libfiles)) do
            if not libfile:endswith(".dll") then
                table.insert(result, libfile)
            end
        end
        return table.unwrap(result)
    end
    for _, pkg in ipairs(self:orderpkgs(opt)) do
        local configinfo = self:pkgconfig(pkg:name())
        -- get values from package components
        -- e.g. `add_packages("sfml", {components = {"graphics", "window"}})`
        local selected_components = configinfo and configinfo.components or pkg:components_default()
        if selected_components and pkg:components() then
            local components_enabled = hashset.new()
            for _, comp in ipairs(table.wrap(selected_components)) do
                components_enabled:insert(comp)
                for _, dep in ipairs(table.wrap(pkg:component_orderdeps(comp))) do
                    components_enabled:insert(dep)
                end
            end
            components_enabled:insert("__base")
            -- if we can't find the values from the component, we need to fall back to __base to find them.
            -- it contains some common values of all components
            local values = {}
            local components = table.wrap(pkg:components())
            for _, component_name in ipairs(table.join(pkg:components_orderlist(), "__base")) do
                if components_enabled:has(component_name) then
                    local info = components[component_name]
                    if info then
                        local compvalues = info[name]
                        -- use full link path instead of links
                        -- @see https://github.com/xmake-io/xmake/issues/5066
                        if configinfo and configinfo.linkpath then
                            local libfiles = info.libfiles
                            if name == "links" then
                                if libfiles then
                                    compvalues = _filter_libfiles(libfiles)
                                end
                            elseif name == "linkdirs" then
                                if libfiles then
                                    compvalues = nil
                                end
                            end
                        end
                        table.join2(values, compvalues)
                    else
                        local components_str = table.concat(table.wrap(configinfo.components), ", ")
                        utils.warning("unknown component(%s) in add_packages(%s, {components = {%s}})", component_name, pkg:name(), components_str)
                    end
                end
            end
            if #values > 0 then
                table.insert(result_values, values)
                table.insert(result_sources, "package::" .. pkg:name())
            end
        -- get values instead of the builtin configs if exists extra package config
        -- e.g. `add_packages("xxx", {links = "xxx"})`
        elseif configinfo and configinfo[name] then
             local values = configinfo[name]
             if values ~= nil then
                table.insert(result_values, values)
                table.insert(result_sources, "package::" .. pkg:name())
            end
        else
            -- get values from the builtin package configs
            local values = pkg:get(name)
            -- use full link path instead of links
            -- @see https://github.com/xmake-io/xmake/issues/5066
            if configinfo and configinfo.linkpath then
                local libfiles = pkg:libraryfiles()
                if name == "links" then
                    if libfiles then
                        values = _filter_libfiles(libfiles)
                    end
                elseif name == "linkdirs" then
                    if libfiles then
                        values = nil
                    end
                end
            end
            if values ~= nil then
                table.insert(result_values, values)
                table.insert(result_sources, "package::" .. pkg:name())
            end
        end
    end
end

-- get values from the given source
function _instance:_get_from_source(name, source, result_values, result_sources, opt)
    if source == "self" then
        local values = self:get(name, opt)
        if values ~= nil then
            table.insert(result_values, values)
            table.insert(result_sources, "self")
        end
    elseif source:startswith("dep::") then
        local depname = source:split("::", {plain = true, limit = 2})[2]
        if depname == "*" then
            self:_get_from_deps(name, result_values, result_sources, opt)
        else
            local depsource
            local splitinfo = depname:split("/", {plain = true})
            if #splitinfo == 2 then
                depname = splitinfo[1]
                depsource = splitinfo[2]
            end
            local dep = self:dep(depname)
            if dep then
                -- e.g.
                -- dep::foo/option::bar
                -- dep::foo/package::bar
                if depsource then
                    local dep_values = {}
                    local dep_sources = {}
                    dep:_get_from_source(name, depsource, dep_values, dep_sources, opt)
                    for idx, values in ipairs(dep_values) do
                        local dep_source = dep_sources[idx]
                        table.insert(result_values, values)
                        table.insert(result_sources, "dep::" .. depname .. "/" .. dep_source)
                    end
                else
                    -- dep::foo
                    local values = dep:get(name, opt)
                    if values ~= nil then
                        table.insert(result_values, values)
                        table.insert(result_sources, source)
                    end
                end
            end
        end
    elseif source:startswith("option::") then
        local optname = source:split("::", {plain = true, limit = 2})[2]
        if optname == "*" then
            self:_get_from_options(name, result_values, result_sources, opt)
        else
            local opt_ = self:opt(optname, opt)
            if opt_ then
                local values = opt_:get(name)
                if values ~= nil then
                    table.insert(result_values, values)
                    table.insert(result_sources, source)
                end
            end
        end
    elseif source:startswith("package::") then
        local pkgname = source:split("::", {plain = true, limit = 2})[2]
        if pkgname == "*" then
            self:_get_from_packages(name, result_values, result_sources, opt)
        else
            local pkg = self:pkg(pkgname, opt)
            if pkg then
                local values = pkg:get(name)
                if values ~= nil then
                    table.insert(result_values, values)
                    table.insert(result_sources, source)
                end
            end
        end
    elseif source == "*" then
        self:_get_from_source(name, "self", result_values, result_sources, opt)
        self:_get_from_source(name, "option::*", result_values, result_sources, opt)
        self:_get_from_source(name, "package::*", result_values, result_sources, opt)
        self:_get_from_source(name, "dep::*", result_values, result_sources, {interface = true})
    else
        os.raise("target:get_from(): unknown source %s", source)
    end
end

-- get the checked target, it's only for target:check_xxx api.
--
-- we should not inherit links from deps/packages when checking snippets in on_config,
-- because the target deps has been not built.
--
-- @see https://github.com/xmake-io/xmake/issues/4491
--
function _instance:_checked_target()
    local checked_target = self._CHECKED_TARGET
    if checked_target == nil then
        checked_target = self:clone()
        -- we need update target:cachekey(), because target flags may be cached in builder
        checked_target:_invalidate()
        checked_target.get_from = function (target, name, sources, opt)
            if (name == "links" or name == "linkdirs") and sources == "*" then
                sources = "self"
            end
            return _instance.get_from(target, name, sources, opt)
        end
        self._CHECKED_TARGET = checked_target
    end
    return checked_target
end

-- get format
function _instance:_format(kind)
    local formats = self._FORMATS
    if not formats then
        for _, toolchain_inst in ipairs(self:toolchains()) do
            formats = toolchain_inst:formats()
            if formats then
                break
            end
        end
        self._FORMATS = formats
    end
    if formats then
        return formats[kind or self:kind()]
    end
end

-- clone target, @note we can just call it in after_load()
function _instance:clone()
    if not self:_is_loaded() then
        os.raise("please call target:clone() in after_load().", self:fullname())
    end
    local instance = target.new(self:fullname(), self._INFO:clone())
    if self._DEPS then
        instance._DEPS = table.clone(self._DEPS)
    end
    if self._ORDERDEPS then
        instance._ORDERDEPS = table.clone(self._ORDERDEPS)
    end
    if self._INHERITDEPS then
        instance._INHERITDEPS = table.clone(self._INHERITDEPS)
    end
    if self._RULES then
        instance._RULES = table.clone(self._RULES)
    end
    if self._ORDERULES then
        instance._ORDERULES = table.clone(self._ORDERULES)
    end
    if self._DATA then
        instance._DATA = table.clone(self._DATA)
    end
    if self._SOURCEFILES then
        instance._SOURCEFILES = table.clone(self._SOURCEFILES)
    end
    if self._OBJECTFILES then
        instance._OBJECTFILES = table.clone(self._OBJECTFILES)
    end
    if self._SOURCEBATCHES then
        instance._SOURCEBATCHES = table.clone(self._SOURCEBATCHES, 3)
    end
    instance._LOADED = self._LOADED
    instance._LOADED_AFTER = true
    return instance
end

-- get the target info
--
-- e.g.
--
-- default: get private
--  - target:get("cflags")
--  - target:get("cflags", {private = true})
--
-- get private and interface
--  - target:get("cflags", {public = true})
--
-- get interface
--  - target:get("cflags", {interface = true})
--
-- get raw reference of values
--  - target:get("cflags", {rawref = true})
--
function _instance:get(name, opt)

    -- get values
    local values = self._INFO:get(name)

    -- get thr required visibility
    local vs_private   = 1
    local vs_interface = 2
    local vs_public    = 3 -- all
    local vs_required  = self:_visibility(opt)

    -- get all values? (private and interface)
    if vs_required == vs_public or (opt and opt.rawref) then
        return values
    end

    -- get the extra configuration
    local extraconf = self:extraconf(name)
    if extraconf then
        -- filter values for public, private or interface if be not dictionary
        if not table.is_dictionary(values) then
            local results = {}
            for _, value in ipairs(table.wrap(values)) do
                -- we always call self:extraconf() to handle group value
                local extra = self:extraconf(name, value)
                local vs_conf = self:_visibility(extra)
                if bit.band(vs_required, vs_conf) ~= 0 then
                    table.insert(results, value)
                end
            end
            if #results > 0 then
                return table.unwrap(results)
            end
        else
            return values
        end
    else
        -- only get the private values
        if bit.band(vs_required, vs_private) ~= 0 then
            return values
        end
    end
end

-- deprecated: get values from target dependencies
function _instance:get_from_deps(name, opt)
    deprecated.add("target:get_from(%s, \"dep:*\")", "target:get_from_deps(%s)", name)
    local result = {}
    local values = self:get_from(name, "dep::*", opt)
    if values then
        for _, v in ipairs(values) do
            table.join2(result, v)
        end
    end
    return result
end

-- deprecated: get values from target options with {interface|public = ...}
function _instance:get_from_opts(name, opt)
    deprecated.add("target:get_from(%s, \"option::*\")", "target:get_from_opts(%s)", name)
    local result = {}
    local values = self:get_from(name, "option::*", opt)
    if values then
        for _, v in ipairs(values) do
            table.join2(result, v)
        end
    end
    return result
end

-- deprecated: get values from target packages with {interface|public = ...}
function _instance:get_from_pkgs(name, opt)
    deprecated.add("target:get_from(%s, \"package::*\")", "target:get_from_pkgs(%s)", name)
    local result = {}
    local values = self:get_from(name, "package::*", opt)
    if values then
        for _, v in ipairs(values) do
            table.join2(result, v)
        end
    end
    return result
end

-- get values from the given sources
--
-- e.g.
--
-- only from the current target:
--      target:get_from("links")
--      target:get_from("links", "self")
--
-- from the given dep:
--      target:get_from("links", "dep::foo")
--      target:get_from("links", "dep::foo", {interface = true})
--      target:get_from("links", "dep::*")
--
-- from the given option:
--      target:get_from("links", "option::foo")
--      target:get_from("links", "option::*")
--
-- from the given package:
--      target:get_from("links", "package::foo")
--      target:get_from("links", "package::*")
--
-- from the given dep/option, dep/package
--      target:get_from("links", "dep::foo/option::bar")
--      target:get_from("links", "dep::foo/option::*")
--      target:get_from("links", "dep::foo/package::bar")
--      target:get_from("links", "dep::foo/package::*")
--
-- from the multiple sources:
--      target:get_from("links", {"self", "option::foo", "dep::bar", "package::zoo"})
--      target:get_from("links", {"self", "option::*", "dep::*", "package::*"})
--
-- from all:
--      target:get_from("links", "*")
--
-- return:
--      local values, sources = target:get_from("links", "*")
--      for idx, value in ipairs(values) do
--          local source = sources[idx]
--      end
--
function _instance:get_from(name, sources, opt)
    local result_values = {}
    local result_sources = {}
    sources = sources or "self"
    for _, source in ipairs(table.wrap(sources)) do
        self:_get_from_source(name, source, result_values, result_sources, opt)
    end
    if #result_values > 0 then
        return result_values, result_sources
    end
end

-- set the value to the target info
function _instance:set(name, ...)
    self._INFO:apival_set(name, ...)
    self:_invalidate(name)
end

-- add the value to the target info
function _instance:add(name, ...)
    self._INFO:apival_add(name, ...)
    self:_invalidate(name)
end

-- remove the value to the target info (deprecated)
function _instance:del(name, ...)
    self._INFO:apival_del(name, ...)
    self:_invalidate(name)
end

-- remove the value to the target info
function _instance:remove(name, ...)
    self._INFO:apival_remove(name, ...)
    self:_invalidate(name)
end

-- get the extra configuration
function _instance:extraconf(name, item, key)
    return self._INFO:extraconf(name, item, key)
end

-- set the extra configuration
function _instance:extraconf_set(name, item, key, value)
    self._INFO:extraconf_set(name, item, key, value)
end

-- get the extra configuration from the given source
--
-- e.g.
--
-- only from the current target:
--      target:extraconf_from("links")
--      target:extraconf_from("links", "self")
--
-- from the given dep:
--      target:extraconf_from("links", "dep::foo")
--
-- from the given option:
--      target:extraconf_from("links", "option::foo")
--
-- from the given package:
--      target:extraconf_from("links", "package::foo")
--
-- from the given dep/option, dep/package
--      target:extraconf_from("links", "dep::foo/option::bar")
--      target:extraconf_from("links", "dep::foo/package::bar")
--
function _instance:extraconf_from(name, source)
    if name:find("::") then
        local tmp = name
        name = source
        source = tmp
        utils.warning("please use target:extraconf_from(%s, %s) intead of target:extraconf_from(%s, %s)", name, source, source, name)
    end
    source = source or "self"
    if source == "self" then
        return self:extraconf(name)
    elseif source:startswith("dep::") then
        local depname = source:split("::", {plain = true, limit = 2})[2]
        local depsource
        local splitinfo = depname:split("/", {plain = true})
        if #splitinfo == 2 then
            depname = splitinfo[1]
            depsource = splitinfo[2]
        end
        local dep = self:dep(depname)
        if dep then
            -- e.g.
            -- dep::foo/option::bar
            -- dep::foo/package::bar
            if depsource then
                return dep:extraconf_from(name, dep_source)
            else
                -- dep::foo
                return dep:extraconf(name)
            end
        end
    elseif source:startswith("option::") then
        local optname = source:split("::", {plain = true, limit = 2})[2]
        local opt_ = self:opt(optname, opt)
        if opt_ then
            return opt_:extraconf(name)
        end
    elseif source:startswith("package::") then
        local pkgname = source:split("::", {plain = true, limit = 2})[2]
        local pkg = self:pkg(pkgname, opt)
        if pkg then
            return pkg:extraconf(name)
        end
    else
        os.raise("target:extraconf_from(): unknown source %s", source)
    end
end

-- get configuration source information of the given api item
function _instance:sourceinfo(name, item)
    return self._INFO:sourceinfo(name, item)
end

-- get user private data
function _instance:data(name)
    return self._DATA and self._DATA[name]
end

-- set user private data
function _instance:data_set(name, data)
    self._DATA = self._DATA or {}
    self._DATA[name] = data
end

-- add user private data
function _instance:data_add(name, data)
    self._DATA = self._DATA or {}
    self._DATA[name] = table.unwrap(table.join(self._DATA[name] or {}, data))
end

-- get values
function _instance:values(name, sourcefile)

    -- get values from the source file first
    local values = {}
    if sourcefile then
        local fileconfig = self:fileconfig(sourcefile)
        if fileconfig then
            local filevalues = fileconfig.values
            if filevalues then
                -- we use '_' to simplify setting, for example:
                --
                -- add_files("xxx.mof", {values = {wdk_mof_header = "xxx.h"}})
                -- add_files("xxx.mof", {values = {["wdk.mof.header"] = "xxx.h"}})
                --
                table.join2(values, filevalues[name] or filevalues[name:gsub("%.", "_")])
            end
        end
    end

    -- get values from target
    table.join2(values, self:get("values." .. name))
    if #values > 0 then
        values = table.unwrap(values)
    else
        values = nil
    end
    return values
end

-- set values
function _instance:values_set(name, ...)
    self:set("values." .. name, ...)
end

-- add values
function _instance:values_add(name, ...)
    self:add("values." .. name, ...)
end

-- get the target info
function _instance:info()
    return self._INFO:info()
end

-- get the type: target
function _instance:type()
    return "target"
end

-- get the target name
function _instance:name()
    return self._NAME
end

-- set the target name
function _instance:name_set(name)
    local parts = name:split("::", {plain = true})
    self._NAME = parts[#parts]
    table.remove(parts)
    if #parts > 0 then
        self._NAMESPACE = table.concat(parts, "::")
    end
end

-- get the namespace
function _instance:namespace()
    return self._NAMESPACE
end

-- get the full name
function _instance:fullname()
    local namespace = self:namespace()
    return namespace and namespace .. "::" .. self:name() or self:name()
end

-- get the target kind
function _instance:kind()
    return self:get("kind") or "binary"
end

-- get the target kind (deprecated)
function _instance:targetkind()
    return self:kind()
end

-- get the platform of this target
function _instance:plat()
    return self:get("plat") or config.get("plat") or os.host()
end

-- get the architecture of this target
function _instance:arch()
    return self:get("arch") or config.get("arch") or os.arch()
end

-- the current target is belong to the given platforms?
function _instance:is_plat(...)
    local plat = self:plat()
    for _, v in ipairs(table.pack(...)) do
        if v and plat == v then
            return true
        end
    end
end

-- the current target is belong to the given architectures?
function _instance:is_arch(...)
    local arch = self:arch()
    for _, v in ipairs(table.pack(...)) do
        if v and arch:find("^" .. v:gsub("%-", "%%-") .. "$") then
            return true
        end
    end
end

-- is 64bits architecture?
function _instance:is_arch64()
    return self:is_arch(".+64.*")
end

-- get the platform instance
function _instance:platform()
    local platform_inst = self._PLATFORM
    if platform_inst == nil then
        platform_inst, errors = platform.load(self:plat(), self:arch())
        if not platform_inst then
            os.raise(errors)
        end
        self._PLATFORM = platform_inst
    end
    return platform_inst
end

-- get the cache key
function _instance:cachekey()
    return string.format("%s_%d", tostring(self), self._CACHEID)
end

-- get the target version
function _instance:version()
    local version = self:get("version")
    local version_build
    if version then
        version_build = self:extraconf("version", version, "build")
        if type(version_build) == "string" then
            version_build = os.date(version_build, os.time())
        end
    end
    return version, version_build
end

-- get the target soname
-- @see https://github.com/tboox/tbox/issues/214
--
-- set_version("1.0.1", {soname = "1.0"}) -> libfoo.so.1.0, libfoo.1.0.dylib
-- set_version("1.0.1", {soname = "1"}) -> libfoo.so.1, libfoo.1.dylib
-- set_version("1.0.1", {soname = true}) -> libfoo.so.1, libfoo.1.dylib
-- set_version("1.0.1", {soname = ""}) -> libfoo.so, libfoo.dylib
function _instance:soname()
    if not self:is_shared() then
        return
    end
    if self:is_plat("windows", "mingw", "cygwin", "msys") then
        return
    end
    local version = self:get("version")
    local version_soname
    if version then
        version_soname = self:extraconf("version", version, "soname")
        if version_soname == true then
            version_soname = version:split(".", {plain = true})[1]
        end
    end
    if not version_soname then
        return
    end
    local soname = self:filename()
    if type(version_soname) == "string" and #version_soname > 0 then
        local extension = path.extension(soname)
        if extension == ".dylib" then
            soname = path.basename(soname) .. "." .. version_soname .. extension
        else
            soname = soname .. "." .. version_soname
        end
    end
    return soname
end

-- get the target license
function _instance:license()
    return self:get("license")
end

-- get the target policy
function _instance:policy(name)
    local policies = self._POLICIES
    if not policies then
        policies = self:get("policy")
        self._POLICIES = policies
        if policies then
            local defined_policies = policy.policies()
            for name, _ in pairs(policies) do
                if not defined_policies[name] then
                    utils.warning("unknown policy(%s), please run `xmake l core.project.policy.policies` if you want to all policies", name)
                end
            end
        end
    end
    local value
    if policies then
        value = policies[name]
    end
    if value == nil and target._project() then
        value = target._project().policy(name)
    end
    return policy.check(name, value)
end

-- get the base name of target file
function _instance:basename()
    local filename = self:get("filename")
    if filename then
        return path.basename(filename)
    end
    return self:get("basename") or self:name()
end

-- get the target compiler
function _instance:compiler(sourcekind)
    local compilerinst = self:_memcache():get("compiler")
    if not compilerinst then
        if not sourcekind then
            os.raise("please pass sourcekind to the first argument of target:compiler(), e.g. cc, cxx, as")
        end
        local instance, errors = compiler.load(sourcekind, self)
        if not instance then
            os.raise(errors)
        end
        compilerinst = instance
        self:_memcache():set("compiler", compilerinst)
    end
    return compilerinst
end

-- get the target linker
function _instance:linker()
    local linkerinst = self:_memcache():get("linker")
    if not linkerinst then
        local instance, errors = linker.load(self:kind(), self:sourcekinds(), self)
        if not instance then
            os.raise(errors)
        end
        linkerinst = instance
        self:_memcache():set("linker", linkerinst)
    end
    return linkerinst
end

-- make linking command for this target
function _instance:linkcmd(objectfiles)
    return self:linker():linkcmd(objectfiles or self:objectfiles(), self:targetfile(), {target = self})
end

-- make linking arguments for this target
function _instance:linkargv(objectfiles)
    return self:linker():linkargv(objectfiles or self:objectfiles(), self:targetfile(), {target = self})
end

-- make link flags for the given target
function _instance:linkflags()
    return self:linker():linkflags({target = self})
end

-- get the given dependent target
function _instance:dep(name)
    local deps = self:deps()
    if deps then
        local dep = deps[name]
        if dep == nil then
            local namespace = self:namespace()
            if namespace then
                dep = deps[namespace .. "::" .. name]
            end
        end
        return dep
    end
end

-- get target deps
function _instance:deps()
    if not self:_is_loaded() then
        os.raise("please call target:deps() or target:dep() in after_load()!")
    end
    if self._DEPS == nil then
        self:_build_deps()
    end
    return self._DEPS
end

-- get target ordered deps
function _instance:orderdeps(opt)
    opt = opt or {}
    if not self:_is_loaded() then
        os.raise("please call target:orderdeps() in after_load()!")
    end
    if self._DEPS == nil then
        self:_build_deps()
    end
    return opt.inherit and self._INHERITDEPS or self._ORDERDEPS
end

-- get target rules
function _instance:rules()
    return self._RULES
end

-- get target ordered rules
function _instance:orderules()
    local rules = self._RULES
    local orderules = self._ORDERULES
    if orderules == nil and rules then
        orderules = instance_deps.sort(rules)
        self._ORDERULES = orderules
    end
    return orderules
end

-- get target rule from the given rule name
function _instance:rule(name)
    if self._RULES then
        local r = self._RULES[name]
        if r == nil and self:namespace() then
            r = self._RULES[self:namespace() .. "::" .. name]
        end
        return r
    end
end

-- add rule
--
-- @note If a rule has the same name as a built-in rule,
-- it will be replaced in the target:rules() and target:orderules(), but will be not replaced globally in the project.rules()
function _instance:rule_add(r)
    self._RULES = self._RULES or {}
    self._RULES[r:fullname()] = r
    self._ORDERULES = nil
end

-- is phony target?
function _instance:is_phony()
    local targetkind = self:kind()
    return not targetkind or targetkind == "phony"
end

-- is binary target?
function _instance:is_binary()
    return self:kind() == "binary"
end

-- is shared library target?
function _instance:is_shared()
    return self:kind() == "shared"
end

-- is static library target?
function _instance:is_static()
    return self:kind() == "static"
end

-- is object files target?
function _instance:is_object()
    return self:kind() == "object"
end

-- is headeronly target?
function _instance:is_headeronly()
    return self:kind() == "headeronly"
end

-- is moduleonly target?
function _instance:is_moduleonly()
    return self:kind() == "moduleonly"
end

-- is library target?
function _instance:is_library()
    return self:is_static() or self:is_shared() or self:is_headeronly() or self:is_moduleonly()
end

-- is default target?
function _instance:is_default()
    local default = self:get("default")
    return default == nil or default == true
end

-- is enabled?
function _instance:is_enabled()
    return self:get("enabled") ~= false
end

-- is rebuilt?
function _instance:is_rebuilt()
    return self:data("rebuilt")
end

-- is cross-compilation?
function _instance:is_cross()
    return is_cross(self:plat(), self:arch())
end

-- get the enabled option
function _instance:opt(name, opt)
    return self:opts(opt)[name]
end

-- get the enabled options
function _instance:opts(opt)
    opt = opt or {}
    local cachekey = "opts"
    if opt.public then
        cachekey = cachekey .. "_public"
    elseif opt.interface then
        cachekey = cachekey .. "_interface"
    end
    local opts = self:_memcache():get(cachekey)
    if not opts then
        opts = {}
        for _, opt_ in ipairs(self:orderopts(opt)) do
            opts[opt_:name()] = opt_
        end
        self:_memcache():set(cachekey, opts)
    end
    return opts
end

-- get the enabled ordered options with {public|interface = ...}
function _instance:orderopts(opt)
    opt = opt or {}
    local cachekey = "orderopts"
    if opt.public then
        cachekey = cachekey .. "_public"
    elseif opt.interface then
        cachekey = cachekey .. "_interface"
    end
    local orderopts = self:_memcache():get(cachekey)
    if not orderopts then
        orderopts = {}
        for _, name in ipairs(table.wrap(self:get("options", opt))) do
            local opt_ = nil
            local enabled = config.get(name)
            if enabled == nil and self:namespace() then
                enabled = config.get(self:namespace() .. "::" .. name)
            end
            if enabled then
                opt_ = option.load(name, {namespace = self:namespace()})
            end
            if opt_ then
                table.insert(orderopts, opt_)
            end
        end
        self:_memcache():set(cachekey, orderopts)
    end
    return orderopts
end

-- get the enabled package
function _instance:pkg(name, opt)
    return self:pkgs(opt)[name]
end

-- get the enabled packages
function _instance:pkgs(opt)
    opt = opt or {}
    local cachekey = "pkgs"
    if opt.public then
        cachekey = cachekey .. "_public"
    elseif opt.interface then
        cachekey = cachekey .. "_interface"
    end
    local packages = self:_memcache():get(cachekey)
    if not packages then
        packages = {}
        for _, pkg in ipairs(self:orderpkgs(opt)) do
            packages[pkg:name()] = pkg
        end
        self:_memcache():set(cachekey, packages)
    end
    return packages
end

-- get the required packages with {interface|public = ..}
function _instance:orderpkgs(opt)
    opt = opt or {}
    local cachekey = "orderpkgs"
    if opt.public then
        cachekey = cachekey .. "_public"
    elseif opt.interface then
        cachekey = cachekey .. "_interface"
    end
    local packages = self:_memcache():get(cachekey)
    if not packages then
        packages = {}
        local requires = target._project().required_packages()
        if requires then
            for _, packagename in ipairs(table.wrap(self:get("packages", opt))) do
                local pkg = requires[packagename]
                -- attempt to get package with namespace
                if pkg == nil and packagename:find("::", 1, true) then
                    local parts = packagename:split("::", {plain = true})
                    local namespace_pkg = requires[parts[#parts]]
                    if namespace_pkg and namespace_pkg:namespace() then
                        local fullname = namespace_pkg:fullname()
                        if fullname:endswith(packagename) then
                            pkg = namespace_pkg
                        end
                    end
                end
                if pkg and pkg:enabled() then
                    table.insert(packages, pkg)
                end
            end
        end
        self:_memcache():set(cachekey, packages)
    end
    return packages
end

-- get the environments of packages
function _instance:pkgenvs()
    local pkgenvs = self._PKGENVS
    if pkgenvs == nil then
        local pkgs = hashset.new()
        for _, pkgname in ipairs(table.wrap(self:get("packages"))) do
            local pkg = self:pkg(pkgname)
            if pkg then
                pkgs:insert(pkg)
            end
        end
        -- we can also get package envs from deps (public package)
        -- @see https://github.com/xmake-io/xmake/issues/2729
        for _, dep in ipairs(self:orderdeps()) do
            for _, pkgname in ipairs(table.wrap(dep:get("packages", {interface = true}))) do
                local pkg = dep:pkg(pkgname)
                if pkg then
                    pkgs:insert(pkg)
                end
            end
        end
        for _, pkg in pkgs:orderkeys() do
            local envs = pkg:envs()
            if envs then
                for name, values in table.orderpairs(envs) do
                    if type(values) == "table" then
                        values = path.joinenv(values)
                    end
                    pkgenvs = pkgenvs or {}
                    if pkgenvs[name] then
                        pkgenvs[name] = pkgenvs[name] .. path.envsep() .. values
                    else
                        pkgenvs[name] = values
                    end
                end
            end
        end
        self._PKGENVS = pkgenvs or false
    end
    return pkgenvs or nil
end

-- get the config info of the given package
function _instance:pkgconfig(pkgname)
    local extra_packages = self:extraconf("packages")
    if extra_packages then
        return extra_packages[pkgname]
    end
end

-- get the object files directory
function _instance:objectdir(opt)

    -- the object directory
    local objectdir = self:get("objectdir")
    if not objectdir then
        objectdir = path.join(config.buildir(), ".objs")
    end
    local namespace = self:namespace()
    if namespace then
        objectdir = path.join(objectdir, (namespace:replace("::", path.sep())), self:name())
    else
        objectdir = path.join(objectdir, self:name())
    end

    -- get root directory of target
    local intermediate_directory = self:policy("build.intermediate_directory")
    if (opt and opt.root) or intermediate_directory == false then
        return objectdir
    end

    -- generate intermediate directory
    local plat = self:plat()
    if plat then
        objectdir = path.join(objectdir, plat)
    end
    local arch = self:arch()
    if arch then
        objectdir = path.join(objectdir, arch)
    end
    local mode = config.mode()
    if mode then
        objectdir = path.join(objectdir, mode)
    end
    return objectdir
end

-- get the dependent files directory
function _instance:dependir(opt)

    -- init the dependent directory
    local dependir = self:get("dependir")
    if not dependir then
        dependir = path.join(config.buildir(), ".deps")
    end
    local namespace = self:namespace()
    if namespace then
        dependir = path.join(dependir, (namespace:replace("::", path.sep())), self:name())
    else
        dependir = path.join(dependir, self:name())
    end

    -- get root directory of target
    local intermediate_directory = self:policy("build.intermediate_directory")
    if (opt and opt.root) or intermediate_directory == false then
        return dependir
    end

    -- generate intermediate directory
    local plat = self:plat()
    if plat then
        dependir = path.join(dependir, plat)
    end
    local arch = self:arch()
    if arch then
        dependir = path.join(dependir, arch)
    end
    local mode = config.mode()
    if mode then
        dependir = path.join(dependir, mode)
    end
    return dependir
end

-- get the autogen files directory
function _instance:autogendir(opt)

    -- init the autogen directory
    local autogendir = self:get("autogendir")
    if not autogendir then
        autogendir = path.join(config.buildir(), ".gens")
    end
    local namespace = self:namespace()
    if namespace then
        autogendir = path.join(autogendir, (namespace:replace("::", path.sep())), self:name())
    else
        autogendir = path.join(autogendir, self:name())
    end

    -- get root directory of target
    local intermediate_directory = self:policy("build.intermediate_directory")
    if (opt and opt.root) or intermediate_directory == false then
        return autogendir
    end

    -- generate intermediate directory
    local plat = self:plat()
    if plat then
        autogendir = path.join(autogendir, plat)
    end
    local arch = self:arch()
    if arch then
        autogendir = path.join(autogendir, arch)
    end
    local mode = config.mode()
    if mode then
        autogendir = path.join(autogendir, mode)
    end
    return autogendir
end

-- get the autogen file path from the given source file path
function _instance:autogenfile(sourcefile, opt)

    -- get relative directory in the autogen directory
    local relativedir = nil
    local origindir  = path.directory(path.absolute(sourcefile))
    local autogendir = path.absolute(self:autogendir())
    if origindir:startswith(autogendir) then
        relativedir = path.join("gens", path.relative(origindir, autogendir))
    end

    -- get relative directory in the source directory
    if not relativedir then
        relativedir = path.directory(sourcefile)
    end

    -- translate path
    --
    -- e.g.
    --
    -- src/xxx.c
    --      project/xmake.lua
    --          build/.objs
    --          build/.gens
    --
    -- objectfile: project/build/.objs/xxxx/../../xxx.c will be out of range for objectdir
    -- autogenfile: project/build/.gens/xxxx/../../xxx.c will be out of range for autogendir
    --
    -- we need to replace '..' with '__' in this case
    --
    if path.is_absolute(relativedir) and os.host() == "windows" then
        -- remove C:\\ and whitespaces and fix long path issue
        -- e.g. C:\\Program Files (x64)\\xxx\Windows.h
        --
        -- @see
        -- https://github.com/xmake-io/xmake/issues/3021
        -- https://github.com/xmake-io/xmake/issues/3715
        relativedir = hash.strhash128(relativedir)
    end
    relativedir = relativedir:gsub("%.%.", "__")
    local rootdir = (opt and opt.rootdir) and opt.rootdir or self:autogendir()
    if relativedir ~= "." then
        rootdir = path.join(rootdir, relativedir)
    end
    return path.join(rootdir, (opt and opt.filename) and opt.filename or path.filename(sourcefile))
end

-- get the target directory
function _instance:targetdir()

    -- the target directory
    local targetdir = self:get("targetdir")
    if not targetdir then
        targetdir = config.buildir()

        -- get root directory of target
        local intermediate_directory = self:policy("build.intermediate_directory")
        if intermediate_directory == false then
            return targetdir
        end

        -- generate intermediate directory
        local plat = self:plat()
        if plat then
            targetdir = path.join(targetdir, plat)
        end
        local arch = self:arch()
        if arch then
            targetdir = path.join(targetdir, arch)
        end
        local mode = config.mode()
        if mode then
            targetdir = path.join(targetdir, mode)
        end
        local namespace = self:namespace()
        if namespace then
            targetdir = path.join(targetdir, (namespace:replace("::", path.sep())))
        end
    end
    return targetdir
end

-- get the target file name
function _instance:filename()

    -- no target file?
    if self:is_object() or self:is_phony() or self:is_headeronly() or self:is_moduleonly() then
        return
    end

    -- make the target file name and attempt to use the format of linker first
    local targetkind = self:targetkind()
    local filename = self:get("filename")
    if not filename then
        local prefixname = self:get("prefixname")
        local suffixname = self:get("suffixname")
        local extension  = self:get("extension")
        filename = target.filename(self:basename(), targetkind, {
            format = self:_format(),
            plat = self:plat(), arch = self:arch(),
            prefixname = prefixname,
            suffixname = suffixname,
            extension = extension})
    end
    return filename
end

-- get the link name only for static/shared library
function _instance:linkname()
    if self:is_static() or self:is_shared() then
        local filename = self:get("filename")
        if filename then
            return target.linkname(filename)
        else
            local linkname = self:basename()
            local suffixname = self:get("suffixname")
            if suffixname then
                linkname = linkname .. suffixname
            end
            return linkname
        end
    end
end

-- get the target file
function _instance:targetfile()
    local filename = self:filename()
    if filename then
        return path.join(self:targetdir(), filename)
    end
end

-- get the symbol file
function _instance:symbolfile()

    -- the target directory
    local targetdir = self:targetdir()
    assert(targetdir and type(targetdir) == "string")

    -- the symbol file name
    local prefixname = self:get("prefixname")
    local suffixname = self:get("suffixname")
    local filename = target.filename(self:basename(), "symbol", {
        plat = self:plat(), arch = self:arch(),
        format = self:_format("symbol"),
        prefixname = prefixname,
        suffixname = suffixname})
    assert(filename)

    -- make the symbol file path
    return path.join(targetdir, filename)
end

-- get the script directory of xmake.lua
function _instance:scriptdir()
    return self:get("__scriptdir")
end

-- get configuration output directory
function _instance:configdir()
    return self:get("configdir") or config.buildir()
end

-- get run directory
function _instance:rundir()
    return baseoption.get("workdir") or self:get("rundir") or path.directory(self:targetfile())
end

-- get prefix directory
function _instance:prefixdir()
    return self:get("prefixdir")
end

-- get the installed binary directory
function _instance:bindir()
    local bindir = self:extraconf("prefixdir", self:prefixdir(), "bindir")
    if bindir == nil then
        bindir = "bin"
    end
    return self:installdir(bindir)
end

-- get the installed library directory
function _instance:libdir()
    local libdir = self:extraconf("prefixdir", self:prefixdir(), "libdir")
    if libdir == nil then
        libdir = "lib"
    end
    return self:installdir(libdir)
end

-- get the installed include directory
function _instance:includedir()
    local includedir = self:extraconf("prefixdir", self:prefixdir(), "includedir")
    if includedir == nil then
        includedir = "include"
    end
    return self:installdir(includedir)
end

-- get install directory
function _instance:installdir(...)
    opt = opt or {}
    local installdir = baseoption.get("installdir")
    if not installdir then
        -- DESTDIR: be compatible with https://www.gnu.org/prep/standards/html_node/DESTDIR.html
        installdir = self:get("installdir") or os.getenv("INSTALLDIR") or os.getenv("PREFIX") or os.getenv("DESTDIR") or platform.get("installdir")
        if installdir then
            installdir = installdir:trim()
        end
    end
    if installdir then
        local prefixdir = self:prefixdir()
        if prefixdir then
            installdir = path.join(installdir, prefixdir)
        end
        return path.normalize(path.join(installdir, ...))
    end
end

-- get package directory
function _instance:packagedir()
    -- get the output directory
    local outputdir   = baseoption.get("outputdir") or config.buildir()
    local packagename = self:name():lower()
    if #packagename > 1 and bit.band(packagename:byte(2), 0xc0) == 0x80 then
        utils.warning("package(%s): cannot generate package, becauese it contains unicode characters!", packagename)
        return
    end
    return path.join(outputdir, "packages", packagename:sub(1, 1), packagename)
end

-- get rules of the source file
function _instance:filerules(sourcefile)

    -- add rules from file config
    local rules = {}
    local override = false
    local fileconfig = self:fileconfig(sourcefile)
    if fileconfig then
        local filerules = fileconfig.rules or fileconfig.rule
        if filerules then
            override = filerules.override
            for _, rulename in ipairs(table.wrap(filerules)) do
                local r = target._project().rule(rulename, {namespace = self:namespace()}) or
                            rule.rule(rulename) or self:rule(rulename)
                if r then
                    table.insert(rules, r)
                end
            end
        end
    end
    -- override? e.g. add_files("src/*.c", {rules = {"xxx", override = true}})
    if override then
        return rules, true
    end

    -- load all rules for this target with sourcekinds and extensions
    local key2rules = self:_memcache():get("key2rules")
    if not key2rules then
        key2rules = {}
        for _, r in pairs(table.wrap(self:rules())) do
            -- we can also get sourcekinds from add_rules("xxx", {sourcekinds = "cxx"})
            local rule_sourcekinds = self:extraconf("rules", r:name(), "sourcekinds") or r:get("sourcekinds")
            for _, sourcekind in ipairs(table.wrap(rule_sourcekinds)) do
                key2rules[sourcekind] = key2rules[sourcekind] or {}
                table.insert(key2rules[sourcekind], r)
            end
            -- we can also get extensions from add_rules("xxx", {extensions = ".cpp"})
            local rule_extensions = self:extraconf("rules", r:name(), "extensions") or r:get("extensions")
            for _, extension in ipairs(table.wrap(rule_extensions)) do
                extension = extension:lower()
                key2rules[extension] = key2rules[extension] or {}
                table.insert(key2rules[extension], r)
            end
        end
        self:_memcache():set("key2rules", key2rules)
    end

    -- get target rules from the given sourcekind or extension
    --
    -- @note we prefer to use rules with extension because we need to be able to
    -- override the language code rules set by set_sourcekinds
    --
    -- e.g. set_extensions(".bpf.c") will override c++ rules
    --
    local rules_override = {}
    local filename = path.filename(sourcefile):lower()
    for _, r in ipairs(table.wrap(key2rules[path.extension(filename, 2)] or
                                  key2rules[path.extension(filename)] or
                                  key2rules[self:sourcekind_of(filename)])) do
        if self:extraconf("rules", r:name(), "override") then
            table.insert(rules_override, r)
        else
            table.insert(rules, r)
        end
    end

    -- we will use overrided rules first, e.g. add_rules("xxx", {override = true})
    return #rules_override > 0 and rules_override or rules
end

-- get the config info of the given source file
function _instance:fileconfig(sourcefile, opt)
    opt = opt or {}
    local filetype = opt.filetype or "files"

    -- get configs from user, e.g. target:fileconfig_set/add
    -- it has contained all original configs
    if self._FILESCONFIG_USER then
        local filesconfig = self._FILESCONFIG_USER[filetype]
        if filesconfig and filesconfig[sourcefile] then
            return filesconfig[sourcefile]
        end
    end

    -- get orignal configs from `add_xxxfiles()`
    self._FILESCONFIG = self._FILESCONFIG or {}
    local filesconfig = self._FILESCONFIG[filetype]
    if not filesconfig then
        filesconfig = {}
        for filepath, fileconfig in pairs(table.wrap(self:extraconf(filetype))) do
            local results = os.match(filepath)
            if #results > 0 then
                for _, file in ipairs(results) do
                    if path.is_absolute(file) then
                        file = path.relative(file, os.projectdir())
                    end
                    filesconfig[file] = fileconfig
                end
            else
                -- we also need support always_added, @see https://github.com/xmake-io/xmake/issues/1634
                if fileconfig.always_added then
                    filesconfig[filepath] = fileconfig
                end
            end
        end
        self._FILESCONFIG[filetype] = filesconfig
    end
    return filesconfig[sourcefile]
end

-- set the config info to the given source file
function _instance:fileconfig_set(sourcefile, info, opt)
    opt = opt or {}
    self._FILESCONFIG_USER = self._FILESCONFIG_USER or {}
    local filetype = opt.filetype or "files"
    local filesconfig = self._FILESCONFIG_USER[filetype]
    if not filesconfig then
        filesconfig = {}
        self._FILESCONFIG_USER[filetype] = filesconfig
    end
    filesconfig[sourcefile] = info
end

-- add the config info to the given source file
function _instance:fileconfig_add(sourcefile, info, opt)
    opt = opt or {}
    self._FILESCONFIG_USER = self._FILESCONFIG_USER or {}
    local filetype = opt.filetype or "files"
    local filesconfig = self._FILESCONFIG_USER[filetype]
    if not filesconfig then
        filesconfig = {}
        self._FILESCONFIG_USER[filetype] = filesconfig
    end

    -- we fetch orignal configs first if no user configs
    local fileconfig = filesconfig[sourcefile]
    if not fileconfig then
        fileconfig = table.clone(self:fileconfig(sourcefile, opt))
        filesconfig[sourcefile] = fileconfig
    end
    if fileconfig then
        for k, v in pairs(info) do
            if k == "force" then
                -- fileconfig_add("xxx.c", {force = {cxxflags = ""}})
                local force = fileconfig[k] or {}
                for k2, v2 in pairs(v) do
                    if force[k2] then
                        force[k2] = table.join(force[k2], v2)
                    else
                        force[k2] = v2
                    end
                end
                fileconfig[k] = force
            else
                -- fileconfig_add("xxx.c", {cxxflags = ""})
                if fileconfig[k] then
                    fileconfig[k] = table.join(fileconfig[k], v)
                else
                    fileconfig[k] = v
                end
            end
        end
    else
        filesconfig[sourcefile] = info
    end
end

-- get the source files
function _instance:sourcefiles()

    -- cached? return it directly
    if self._SOURCEFILES then
        return self._SOURCEFILES, false
    end

    -- get files
    local files = self:get("files")
    if not files then
        return {}, false
    end

    -- match files
    local i = 1
    local count = 0
    local sourcefiles = {}
    local sourcefiles_removed = {}
    local sourcefiles_inserted = {}
    local removed_count = 0
    local targetcache = memcache.cache("core.project.target")
    for _, file in ipairs(table.wrap(files)) do

        -- mark as removed files?
        local removed = false
        local prefix = "__remove_"
        if file:startswith(prefix) then
            file = file:sub(#prefix + 1)
            removed = true
        end

        -- find source files and try to cache the matching results of os.match across targets
        -- @see https://github.com/xmake-io/xmake/issues/1353
        local results = targetcache:get2("sourcefiles", file)
        if not results then
            if removed then
                results = {file}
            else
                results = os.files(file)
                if #results == 0 then
                    -- attempt to find source directories if maybe compile it as directory with the custom rules
                    if #self:filerules(file) > 0 then
                        results = os.dirs(file)
                    end
                end

                -- Even if the current source file does not exist yet, we always add it.
                -- This is usually used for some rules that automatically generate code files,
                -- because they ensure that the code files have been generated before compilation.
                --
                -- @see https://github.com/xmake-io/xmake/issues/1540
                --
                -- e.g. add_files("src/test.c", {always_added = true})
                --
                if #results == 0 and self:extraconf("files", file, "always_added") then
                    results = {file}
                end
            end
            targetcache:set2("sourcefiles", file, results)
        end
        if #results == 0 then
            local sourceinfo = self:sourceinfo("files", file) or {}
            utils.warning("%s:%d${clear}: cannot match %s_files(\"%s\") in %s(%s)",
                sourceinfo.file or "", sourceinfo.line or -1, (removed and "remove" or "add"), file, self:type(), self:fullname())
        end

        -- process source files
        for _, sourcefile in ipairs(results) do

            -- convert to the relative path
            if path.is_absolute(sourcefile) then
                sourcefile = path.relative(sourcefile, os.projectdir())
            end

            -- add or remove it
            if removed then
                removed_count = removed_count + 1
                table.insert(sourcefiles_removed, sourcefile)
            elseif not sourcefiles_inserted[sourcefile] then
                table.insert(sourcefiles, sourcefile)
                sourcefiles_inserted[sourcefile] = true
            end
        end
    end

    -- remove all source files which need be removed
    if removed_count > 0 then
        table.remove_if(sourcefiles, function (i, sourcefile)
            for _, removed_file in ipairs(sourcefiles_removed) do
                local pattern = path.translate((removed_file:gsub("|.*$", "")))
                if pattern:sub(1, 2):find('%.[/\\]') then
                    pattern = pattern:sub(3)
                end
                pattern = path.pattern(pattern)
                -- we need to match whole pattern, https://github.com/xmake-io/xmake/issues/3523
                if sourcefile:match("^" .. pattern .. "$") then
                    return true
                end
            end
        end)
    end
    self._SOURCEFILES = sourcefiles

    -- ok and sourcefiles are modified
    return sourcefiles, true
end

-- get object file from source file
function _instance:objectfile(sourcefile)
    return self:autogenfile(sourcefile, {rootdir = self:objectdir(),
        filename = target.filename(path.filename(sourcefile), "object", {
            plat = self:plat(),
            arch = self:arch(),
            format = self:_format("object")})})
end

-- get the object files
function _instance:objectfiles()

    -- get source batches
    local sourcebatches, modified = self:sourcebatches()

    -- cached? return it directly
    if self._OBJECTFILES and not modified then
        return self._OBJECTFILES
    end

    -- get object files from source batches
    local objectfiles = {}
    local batchcount = 0
    local sourcebatches = self:sourcebatches()
    local orderkeys = table.keys(sourcebatches)
    table.sort(orderkeys) -- @note we need to guarantee the order of objectfiles for depend.is_changed() and etc.
    for _, k in ipairs(orderkeys) do
        local sourcebatch = sourcebatches[k]
        table.join2(objectfiles, sourcebatch.objectfiles)
        batchcount = batchcount + 1
    end

    -- some object files may be repeat and appear link errors if multi-batches exists, so we need to remove all repeat object files
    -- e.g. add_files("src/*.c", {rules = {"rule1", "rule2"}})
    local deduplicate = batchcount > 1

    -- get object files from all dependent targets (object kind)
    -- @note we only merge objects in plain deps, e.g. binary -> (static -> object, object ...)
    local plaindeps = self:get("deps")
    if plaindeps and (self:is_binary() or self:is_shared() or self:is_static()) then
        local function _get_all_objectfiles_of_object_dep (t)
            local _objectfiles = {}
            table.join2(_objectfiles, t:objectfiles())
            local _plaindeps = t:get("deps")
            if _plaindeps then
                for _, depname in ipairs(table.wrap(_plaindeps)) do
                    local dep = t:dep(depname)
                    if dep and dep:is_object() then
                        table.join2(_objectfiles, _get_all_objectfiles_of_object_dep(dep))
                    end
                end
            end
            return _objectfiles
        end
        for _, depname in ipairs(table.wrap(plaindeps)) do
            local dep = self:dep(depname)
            if dep and dep:is_object() then
                table.join2(objectfiles, _get_all_objectfiles_of_object_dep(dep))
                deduplicate = true
            end
        end
    end

    -- remove repeat object files
    if deduplicate then
        objectfiles = table.unique(objectfiles)
    end

    -- cache it
    self._OBJECTFILES = objectfiles
    return objectfiles
end

-- get the header files
function _instance:headerfiles(outputdir, opt)
    opt = opt or {}
    local headerfiles = self:get("headerfiles", opt) or {}
    -- add_headerfiles("src/*.h", {install = false})
    -- @see https://github.com/xmake-io/xmake/issues/2577
    if opt.installonly then
       local installfiles = {}
       for _, headerfile in ipairs(table.wrap(headerfiles)) do
           if self:extraconf("headerfiles", headerfile, "install") ~= false then
               table.insert(installfiles, headerfile)
           end
       end
       headerfiles = installfiles
    end
    if not headerfiles then
        return
    end

    if not outputdir then
        if self:includedir() then
            outputdir = self:includedir()
        end
    end
    return match_copyfiles(self, "headerfiles", outputdir, {copyfiles = headerfiles})
end

-- get the configuration files
function _instance:configfiles(outputdir)
    return match_copyfiles(self, "configfiles", outputdir or self:configdir(), {pathfilter = function (dstpath, fileinfo)
            if dstpath:endswith(".in") then
                dstpath = dstpath:sub(1, -4)
            end
            return dstpath
        end})
end

-- get the install files
function _instance:installfiles(outputdir, opt)
    local installfiles = self:get("installfiles", opt) or {}
    return match_copyfiles(self, "installfiles", outputdir or self:installdir(), {copyfiles = installfiles})
end

-- get the extra files
function _instance:extrafiles()
    return (match_copyfiles(self, "extrafiles"))
end

-- get depend file from object file
function _instance:dependfile(objectfile)

    -- get the dependent original file and directory, @note relative to the root directory
    local originfile = path.absolute(objectfile and objectfile or self:targetfile())
    local origindir  = path.directory(originfile)

    -- get relative directory in the object directory
    local relativedir = nil
    local objectdir = path.absolute(self:objectdir())
    if origindir:startswith(objectdir) then
        relativedir = path.relative(origindir, objectdir)
    end

    -- get relative directory in the target directory
    if not relativedir then
        local targetdir = path.absolute(self:targetdir())
        if origindir:startswith(targetdir) then
            relativedir = path.relative(origindir, targetdir)
        end
    end

    -- get relative directory in the autogen directory
    if not relativedir then
        local autogendir = path.absolute(self:autogendir())
        if origindir:startswith(autogendir) then
            relativedir = path.join("gens", path.relative(origindir, autogendir))
        end
    end

    -- get relative directory in the build directory
    if not relativedir then
        local buildir = path.absolute(config.buildir())
        if origindir:startswith(buildir) then
            relativedir = path.join("build", path.relative(origindir, buildir))
        end
    end

    -- get relative directory in the project directory
    if not relativedir then
        local projectdir = os.projectdir()
        if origindir:startswith(projectdir) then
            relativedir = path.relative(origindir, projectdir)
        end
    end

    -- get the relative directory from the origin file
    if not relativedir then
        relativedir = origindir
    end
    if path.is_absolute(relativedir) and os.host() == "windows" then
        -- remove C:\\ and whitespaces and fix long path issue
        -- e.g. C:\\Program Files (x64)\\xxx\Windows.h
        --
        -- @see
        -- https://github.com/xmake-io/xmake/issues/3021
        -- https://github.com/xmake-io/xmake/issues/3715
        relativedir = hash.strhash128(relativedir)
    end

    -- originfile: project/build/.objs/xxxx/../../xxx.c will be out of range for objectdir
    --
    -- we need to replace '..' to '__' in this case
    --
    relativedir = relativedir:gsub("%.%.", "__")

    -- make dependent file
    -- full file name(not base) to avoid name-clash of original file
    return path.join(self:dependir(), relativedir, path.filename(originfile) .. ".d")
end

-- get the dependent include files
function _instance:dependfiles()
    local sourcebatches, modified = self:sourcebatches()
    if self._DEPENDFILES and not modified then
        return self._DEPENDFILES
    end
    local dependfiles = {}
    for _, sourcebatch in pairs(self:sourcebatches()) do
        table.join2(dependfiles, sourcebatch.dependfiles)
    end
    self._DEPENDFILES = dependfiles
    return dependfiles
end

-- get the sourcekind for the given source file
function _instance:sourcekind_of(sourcefile)

    -- get the sourcekind of this source file
    local sourcekind = language.sourcekind_of(sourcefile)
    local fileconfig = self:fileconfig(sourcefile)
    if fileconfig and fileconfig.sourcekind then
        -- we can override the sourcekind, e.g. add_files("*.c", {sourcekind = "cxx"})
        sourcekind = fileconfig.sourcekind
    end
    return sourcekind
end

-- get the kinds of sourcefiles
--
-- e.g. cc cxx mm mxx as ...
--
function _instance:sourcekinds()
    local sourcekinds = self._SOURCEKINDS
    if not sourcekinds then
        sourcekinds = {}
        local sourcebatches = self:sourcebatches()
        for _, sourcebatch in table.orderpairs(sourcebatches) do
            local sourcekind = sourcebatch.sourcekind
            if sourcekind then
                table.insert(sourcekinds, sourcekind)
            end
        end
        -- if the source file is added dynamically, we may not be able to get the sourcekinds,
        -- so we can only continue to get it from the rule
        -- https://github.com/xmake-io/xmake/issues/1622#issuecomment-927726697
        for _, ruleinst in ipairs(self:orderules()) do
            local rule_sourcekinds = ruleinst:get("sourcekinds")
            if rule_sourcekinds then
                table.insert(sourcekinds, rule_sourcekinds)
            end
        end
        sourcekinds = table.unique(sourcekinds)
        self._SOURCEKINDS = sourcekinds
    end
    return sourcekinds
end

-- get source count
function _instance:sourcecount()
    return #self:sourcefiles()
end

-- get source batches
function _instance:sourcebatches()

    -- get source files
    local sourcefiles, modified = self:sourcefiles()

    -- cached? return it directly
    if self._SOURCEBATCHES and not modified then
        return self._SOURCEBATCHES, false
    end

    -- make source batches for each source kinds
    local sourcebatches = {}
    for _, sourcefile in ipairs(sourcefiles) do

        -- get file rules
        local filerules, override = self:filerules(sourcefile)
        if #filerules == 0 then
            os.raise("unknown source file: %s", sourcefile)
        end

        -- add source batch for the file rules
        for _, filerule in ipairs(filerules) do

            -- get rule name
            local rulename = filerule:name()

            -- make this batch
            local sourcebatch = sourcebatches[rulename] or {sourcefiles = {}}
            sourcebatches[rulename] = sourcebatch

            -- save the rule name
            sourcebatch.rulename = rulename

            -- add source file to this batch
            table.insert(sourcebatch.sourcefiles, sourcefile)

            -- attempt to get source kind from the builtin languages
            local sourcekind = self:sourcekind_of(sourcefile)
            if sourcekind and filerule:get("sourcekinds") and not override then

                -- save source kind
                sourcebatch.sourcekind = sourcekind

                -- insert object files to source batches
                sourcebatch.objectfiles = sourcebatch.objectfiles or {}
                sourcebatch.dependfiles = sourcebatch.dependfiles or {}
                local objectfile = self:objectfile(sourcefile, sourcekind)
                table.insert(sourcebatch.objectfiles, objectfile)
                table.insert(sourcebatch.dependfiles, self:dependfile(objectfile))
            end
        end
    end
    self._SOURCEBATCHES = sourcebatches
    return sourcebatches, modified
end

-- get xxx_script
function _instance:script(name, generic)

    -- get script
    local script = self:get(name)
    local result = select_script(script, {plat = self:plat(), arch = self:arch()}) or generic

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

-- get the precompiled header file (xxx.[h|hpp|inl])
--
-- @param langkind  c/cxx
--
function _instance:pcheaderfile(langkind)
    local pcheaderfile = self:get("p" .. langkind .. "header")
    if table.empty(pcheaderfile) then
        pcheaderfile = nil
    end
    return pcheaderfile
end

-- set the precompiled header file
function _instance:pcheaderfile_set(langkind, headerfile)
    self:set("p" .. langkind .. "header", headerfile)
    self._PCOUTPUTFILES = nil
end

-- get the output of precompiled header file (xxx.h.pch)
--
-- @param langkind  c/cxx
--
function _instance:pcoutputfile(langkind)
    self._PCOUTPUTFILES = self._PCOUTPUTFILES or {}
    local pcoutputfile = self._PCOUTPUTFILES[langkind]
    if pcoutputfile then
        return pcoutputfile
    end

    -- get the precompiled header file in the object directory
    local pcheaderfile = self:pcheaderfile(langkind)
    if pcheaderfile then
        local is_gcc = false
        local is_msvc = false
        local sourcekinds = {c = "cc", cxx = "cxx", m = "mm", mxx = "mxx"}
        local sourcekind = assert(sourcekinds[langkind], "unknown language kind: " .. langkind)
        local _, toolname = self:tool(sourcekind)
        if toolname then
            if toolname == "gcc" or toolname == "gxx" then
                is_gcc = true
            elseif toolname == "cl" then
                is_msvc = true
            end
        end

        -- make precompiled output file
        --
        -- @note gcc has not -include-pch option to set the pch file path
        --
        pcoutputfile = self:objectfile(pcheaderfile)
        local pcoutputfilename = path.basename(pcoutputfile)
        if is_gcc then
            pcoutputfilename = pcoutputfilename .. ".gch"
        else
            -- different vs versions of pch files are not backward compatible,
            -- so we need to distinguish between them.
            --
            -- @see https://github.com/xmake-io/xmake/issues/5413
            local msvc = self:toolchain("msvc")
            if is_msvc and msvc then
                local vs_toolset = msvc:config("vs_toolset")
                if vs_toolset then
                    vs_toolset = sandbox_module.import("private.utils.toolchain", {anonymous = true}).get_vs_toolset_ver(vs_toolset)
                end
                if vs_toolset then
                    pcoutputfilename = pcoutputfilename .. "_" .. vs_toolset
                end
            end
            pcoutputfilename = pcoutputfilename .. ".pch"
        end
        pcoutputfile = path.join(path.directory(pcoutputfile), sourcekind, pcoutputfilename)
        self._PCOUTPUTFILES[langkind] = pcoutputfile
        return pcoutputfile
    end
end

-- get runtimes
function _instance:runtimes()
    local runtimes = self:_memcache():get("runtimes")
    if runtimes == nil then
        runtimes = self:get("runtimes")
        if runtimes then
            local runtimes_supported = hashset.new()
            local toolchains = self:toolchains() or platform.load(self:plat(), self:arch()):toolchains()
            if toolchains then
                for _, toolchain_inst in ipairs(toolchains) do
                    if toolchain_inst:is_standalone() and toolchain_inst:get("runtimes") then
                        for _, runtime in ipairs(table.wrap(toolchain_inst:get("runtimes"))) do
                            runtimes_supported:insert(runtime)
                        end
                    end
                end
            end
            local runtimes_current = {}
            for _, runtime in ipairs(table.wrap(runtimes)) do
                if runtimes_supported:has(runtime) then
                    table.insert(runtimes_current, runtime)
                end
            end
            runtimes = table.unwrap(runtimes_current)
        end
        runtimes = runtimes or false
        self:_memcache():set("runtimes", runtimes)
    end
    return runtimes or nil
end

-- has the given runtime for the current toolchains?
function _instance:has_runtime(...)
    local runtimes_set = self:_memcache():get("runtimes_set")
    if runtimes_set == nil then
        runtimes_set = hashset.from(table.wrap(self:runtimes()))
        self:_memcache():set("runtimes_set", runtimes_set)
    end
    for _, v in ipairs(table.pack(...)) do
        if runtimes_set:has(v) then
            return true
        end
    end
end

-- get the given toolchain
function _instance:toolchain(name)
    local toolchains_map = self:_memcache():get("toolchains_map")
    if toolchains_map == nil then
        toolchains_map = {}
        for _, toolchain_inst in ipairs(self:toolchains()) do
            toolchains_map[toolchain_inst:name()] = toolchain_inst
        end
        self:_memcache():set("toolchains_map", toolchains_map)
    end
    return toolchains_map[name]
end

-- get the toolchains
function _instance:toolchains()
    local toolchains = self:_memcache():get("toolchains")
    if toolchains == nil then

        -- load target toolchains first
        local has_standalone = false
        local target_toolchains = self:get("toolchains")
        if target_toolchains then
            toolchains = {}
            for _, name in ipairs(table.wrap(target_toolchains)) do
                local toolchain_opt = table.copy(self:extraconf("toolchains", name))
                toolchain_opt.arch = self:arch()
                toolchain_opt.plat = self:plat()
                toolchain_opt.namespace = self:namespace()
                local toolchain_inst, errors = toolchain.load(name, toolchain_opt)
                -- attempt to load toolchain from project
                if not toolchain_inst and target._project() then
                    toolchain_inst = target._project().toolchain(name, toolchain_opt)
                end
                if not toolchain_inst then
                    os.raise(errors)
                end
                if toolchain_inst:is_standalone() then
                    has_standalone = true
                end
                table.insert(toolchains, toolchain_inst)
            end

            -- we always need a standalone toolchain
            -- because we maybe only set partial toolchains in target, e.g. nasm toolchain
            --
            -- @note platform has been checked in config/_check_target_toolchains
            if not has_standalone then
                for _, toolchain_inst in ipairs(self:platform():toolchains()) do
                    if toolchain_inst:is_standalone() then
                        table.insert(toolchains, toolchain_inst)
                        has_standalone = true
                        break
                    end
                end
            end
        else
            toolchains = self:platform():toolchains()
        end

        self:_memcache():set("toolchains", toolchains)
    end
    return toolchains
end

-- get the program and name of the given tool kind
function _instance:tool(toolkind)
    -- we cannot get tool in on_load, because target:toolchains() has been not checked in configuration stage.
    if not self._LOADED_AFTER then
        os.raise("we cannot get tool(%s) before target(%s) is loaded, maybe it is called on_load(), please call it in on_config().", toolkind, self:fullname())
    end
    return toolchain.tool(self:toolchains(), toolkind, {cachekey = "target_" .. self:fullname(), plat = self:plat(), arch = self:arch(),
                                                        before_get = function()
        -- get program from set_toolset
        local program = self:get("toolset." .. toolkind)

        -- get program from `xmake f --cc`
        if not program and not self:get("toolchains") then
            program = config.get(toolkind)
        end

        -- contain toolname? parse it, e.g. 'gcc@xxxx.exe'
        -- https://github.com/xmake-io/xmake/issues/1361
        local toolname
        if program then
            local pos = program:find('@', 1, true)
            if pos then
                -- we need to ignore valid path with `@`, e.g. /usr/local/opt/go@1.17/bin/go
                -- https://github.com/xmake-io/xmake/issues/2853
                local prefix = program:sub(1, pos - 1)
                if prefix and not prefix:find("[/\\]") then
                    toolname = prefix
                    program = program:sub(pos + 1)
                end
            end
        end

        -- find toolname
        if program and not toolname then
            local find_toolname = sandbox_module.import("lib.detect.find_toolname", {anonymous = true})
            toolname = find_toolname(program)
        end
        return program, toolname
    end})
end

-- get tool configuration from the toolchains
function _instance:toolconfig(name)
    return toolchain.toolconfig(self:toolchains(), name, {cachekey = "target_" .. self:fullname(), plat = self:plat(), arch = self:arch(),
                                                          after_get = function(toolchain_inst)
        -- get flags from target.on_xxflags()
        local script = toolchain_inst:get("target.on_" .. name)
        if type(script) == "function" then
            local ok, result_or_errors = utils.trycall(script, nil, self)
            if ok then
                return result_or_errors
            else
                os.raise(result_or_errors)
            end
        end
    end})
end

-- has source files with the given source kind?
function _instance:has_sourcekind(...)
    local sourcekinds_set = self._SOURCEKINDS_SET
    if sourcekinds_set == nil then
        sourcekinds_set = hashset.from(self:sourcekinds())
        self._SOURCEKINDS_SET = sourcekinds_set
    end
    for _, v in ipairs(table.pack(...)) do
        if sourcekinds_set:has(v) then
            return true
        end
    end
end

-- has the given tool for the current target?
--
-- e.g.
--
-- if target:has_tool("cc", "clang", "gcc") then
--    ...
-- end
function _instance:has_tool(toolkind, ...)
    local _, toolname = self:tool(toolkind)
    if toolname then
        for _, v in ipairs(table.pack(...)) do
            if v and toolname:find("^" .. v:gsub("%-", "%%-") .. "$") then
                return true
            end
        end
    end
end

-- has the given c funcs?
--
-- @param funcs     the funcs
-- @param opt       the argument options, e.g. {includes = "xxx.h", configs = {defines = ""}}
--
-- @return          true or false, errors
--
function _instance:has_cfuncs(funcs, opt)
    opt = opt or {}
    opt.target = self
    return sandbox_module.import("lib.detect.has_cfuncs", {anonymous = true})(funcs, opt)
end

-- has the given c++ funcs?
--
-- @param funcs     the funcs
-- @param opt       the argument options, e.g. {includes = "xxx.h", configs = {defines = ""}}
--
-- @return          true or false, errors
--
function _instance:has_cxxfuncs(funcs, opt)
    opt = opt or {}
    opt.target = self
    return sandbox_module.import("lib.detect.has_cxxfuncs", {anonymous = true})(funcs, opt)
end

-- has the given c types?
--
-- @param types     the types
-- @param opt       the argument options, e.g. {configs = {defines = ""}}
--
-- @return          true or false, errors
--
function _instance:has_ctypes(types, opt)
    opt = opt or {}
    opt.target = self
    return sandbox_module.import("lib.detect.has_ctypes", {anonymous = true})(types, opt)
end

-- has the given c++ types?
--
-- @param types     the types
-- @param opt       the argument options, e.g. {configs = {defines = ""}}
--
-- @return          true or false, errors
--
function _instance:has_cxxtypes(types, opt)
    opt = opt or {}
    opt.target = self
    return sandbox_module.import("lib.detect.has_cxxtypes", {anonymous = true})(types, opt)
end

-- has the given c includes?
--
-- @param includes  the includes
-- @param opt       the argument options, e.g. {configs = {defines = ""}}
--
-- @return          true or false, errors
--
function _instance:has_cincludes(includes, opt)
    opt = opt or {}
    opt.target = self
    return sandbox_module.import("lib.detect.has_cincludes", {anonymous = true})(includes, opt)
end

-- has the given c++ includes?
--
-- @param includes  the includes
-- @param opt       the argument options, e.g. {configs = {defines = ""}}
--
-- @return          true or false, errors
--
function _instance:has_cxxincludes(includes, opt)
    opt = opt or {}
    opt.target = self
    return sandbox_module.import("lib.detect.has_cxxincludes", {anonymous = true})(includes, opt)
end

-- has the given c flags?
--
-- @param flags     the flags
-- @param opt       the argument options, e.g. { flagskey = "xxx" }
--
-- @return          true or false, errors
--
function _instance:has_cflags(flags, opt)
    local compinst = self:compiler("cc")
    return compinst:has_flags(flags, "cflags", opt)
end

-- has the given c++ flags?
--
-- @param flags     the flags
-- @param opt       the argument options, e.g. { flagskey = "xxx" }
--
-- @return          true or false, errors
--
function _instance:has_cxxflags(flags, opt)
    local compinst = self:compiler("cxx")
    return compinst:has_flags(flags, "cxxflags", opt)
end

-- has the given features?
--
-- @param features  the features, e.g. {"c_static_assert", "cxx_constexpr"}
-- @param opt       the argument options, e.g. {flags = ""}
--
-- @return          true or false, errors
--
function _instance:has_features(features, opt)
    opt = opt or {}
    opt.target = self:_checked_target()
    return sandbox_module.import("core.tool.compiler", {anonymous = true}).has_features(features, opt)
end

-- check the size of type
--
-- @param typename  the typename
-- @param opt       the argument options, e.g. {includes = "xxx.h", configs = {defines = ""}}
--
-- @return          the type size
--
function _instance:check_sizeof(typename, opt)
    opt = opt or {}
    opt.target = self:_checked_target()
    return sandbox_module.import("lib.detect.check_sizeof", {anonymous = true})(typename, opt)
end

-- check the endianness of compiler
--
-- @param opt       the argument options, e.g. {includes = "xxx.h", configs = {defines = ""}}
--
-- @return          the type size
--
function _instance:check_bigendian(opt)
  opt = opt or {}
  opt.target = self:_checked_target()
  return sandbox_module.import("lib.detect.check_bigendian", {anonymous = true})(opt)
end

-- check the given c snippets?
--
-- @param snippets  the snippets
-- @param opt       the argument options, e.g. {includes = "xxx.h", configs = {defines = ""}}
--
-- @return          true or false, errors
--
function _instance:check_csnippets(snippets, opt)
    opt = opt or {}
    opt.target = self:_checked_target()
    return sandbox_module.import("lib.detect.check_csnippets", {anonymous = true})(snippets, opt)
end

-- check the given c++ snippets?
--
-- @param snippets  the snippets
-- @param opt       the argument options, e.g. {includes = "xxx.h", configs = {defines = ""}}
--
-- @return          true or false, errors
--
function _instance:check_cxxsnippets(snippets, opt)
    opt = opt or {}
    opt.target = self
    return sandbox_module.import("lib.detect.check_cxxsnippets", {anonymous = true})(snippets, opt)
end

-- check the given objc snippets?
--
-- @param snippets  the snippets
-- @param opt       the argument options, e.g. {includes = "xxx.h", configs = {defines = ""}}
--
-- @return          true or false, errors
--
function _instance:check_msnippets(snippets, opt)
    opt = opt or {}
    opt.target = self:_checked_target()
    return sandbox_module.import("lib.detect.check_msnippets", {anonymous = true})(snippets, opt)
end

-- check the given objc++ snippets?
--
-- @param snippets  the snippets
-- @param opt       the argument options, e.g. {includes = "xxx.h", configs = {defines = ""}}
--
-- @return          true or false, errors
--
function _instance:check_mxxsnippets(snippets, opt)
    opt = opt or {}
    opt.target = self:_checked_target()
    return sandbox_module.import("lib.detect.check_mxxsnippets", {anonymous = true})(snippets, opt)
end

-- get project
function target._project()
    return target._PROJECT
end

-- get target apis
function target.apis()

    return
    {
        values =
        {
            -- target.set_xxx
            "target.set_kind"
        ,   "target.set_plat"
        ,   "target.set_arch"
        ,   "target.set_strip"
        ,   "target.set_rules"
        ,   "target.set_group"
        ,   "target.add_filegroups"
        ,   "target.set_version"
        ,   "target.set_license"
        ,   "target.set_enabled"
        ,   "target.set_default"
        ,   "target.set_options"
        ,   "target.set_symbols"
        ,   "target.set_filename"
        ,   "target.set_basename"
        ,   "target.set_extension"
        ,   "target.set_prefixname"
        ,   "target.set_suffixname"
        ,   "target.set_warnings"
        ,   "target.set_fpmodels"
        ,   "target.set_optimize"
        ,   "target.set_runtimes"
        ,   "target.set_languages"
        ,   "target.set_toolchains"
        ,   "target.set_runargs"
        ,   "target.set_exceptions"
        ,   "target.set_encodings"
        ,   "target.set_prefixdir"
            -- target.add_xxx
        ,   "target.add_deps"
        ,   "target.add_rules"
        ,   "target.add_options"
        ,   "target.add_packages"
        ,   "target.add_imports"
        ,   "target.add_languages"
        ,   "target.add_vectorexts"
        ,   "target.add_toolchains"
        ,   "target.add_tests"
        }
    ,   keyvalues =
        {
            -- target.set_xxx
            "target.set_values"
        ,   "target.set_configvar"
        ,   "target.set_runenv"
        ,   "target.set_toolset"
        ,   "target.set_policy"
            -- target.add_xxx
        ,   "target.add_values"
        ,   "target.add_runenvs"
        }
    ,   paths =
        {
            -- target.set_xxx
            "target.set_targetdir"
        ,   "target.set_objectdir"
        ,   "target.set_dependir"
        ,   "target.set_autogendir"
        ,   "target.set_configdir"
        ,   "target.set_installdir"
        ,   "target.set_rundir"
            -- target.add_xxx
        ,   "target.add_files"
        ,   "target.add_cleanfiles"
        ,   "target.add_configfiles"
        ,   "target.add_installfiles"
        ,   "target.add_extrafiles"
            -- target.del_xxx (deprecated)
        ,   "target.del_files"
            -- target.remove_xxx
        ,   "target.remove_files"
        ,   "target.remove_headerfiles"
        ,   "target.remove_configfiles"
        ,   "target.remove_installfiles"
        ,   "target.remove_extrafiles"
        }
    ,   script =
        {
            -- target.on_xxx
            "target.on_run"
        ,   "target.on_test"
        ,   "target.on_load"
        ,   "target.on_config"
        ,   "target.on_link"
        ,   "target.on_build"
        ,   "target.on_build_file"
        ,   "target.on_build_files"
        ,   "target.on_clean"
        ,   "target.on_package"
        ,   "target.on_install"
        ,   "target.on_installcmd"
        ,   "target.on_uninstall"
        ,   "target.on_uninstallcmd"
            -- target.before_xxx
        ,   "target.before_run"
        ,   "target.before_test"
        ,   "target.before_link"
        ,   "target.before_build"
        ,   "target.before_build_file"
        ,   "target.before_build_files"
        ,   "target.before_clean"
        ,   "target.before_package"
        ,   "target.before_install"
        ,   "target.before_installcmd"
        ,   "target.before_uninstall"
        ,   "target.before_uninstallcmd"
            -- target.after_xxx
        ,   "target.after_run"
        ,   "target.after_test"
        ,   "target.after_load"
        ,   "target.after_link"
        ,   "target.after_build"
        ,   "target.after_build_file"
        ,   "target.after_build_files"
        ,   "target.after_clean"
        ,   "target.after_package"
        ,   "target.after_install"
        ,   "target.after_installcmd"
        ,   "target.after_uninstall"
        ,   "target.after_uninstallcmd"
        }
    }
end

-- get the filename from the given target name and kind
function target.filename(targetname, targetkind, opt)
    opt = opt or {}
    assert(targetname and targetkind)

    -- make filename by format
    local filename = targetname
    local format = opt.format or platform.format(targetkind, opt.plat, opt.arch) or "$(name)"
    if format then
        local splitinfo = format:split("$(name)", {plain = true, strict = true})
        local prefixname = splitinfo[1] or ""
        local suffixname = ""
        local extension = splitinfo[2] or ""
        splitinfo = extension:split('.', {plain = true, limit = 2, strict = true})
        if #splitinfo == 2 and splitinfo[1] ~= "" then
            suffixname = splitinfo[1]
            extension  = "." .. splitinfo[2]
        end
        if opt.prefixname then
            prefixname = opt.prefixname
        end
        if opt.suffixname then
            suffixname = opt.suffixname
        end
        if opt.extension then
            extension = opt.extension
        end
        filename = prefixname .. targetname .. suffixname .. extension
    end
    return filename
end

-- get the link name of the target file
function target.linkname(filename, opt)
    -- for implib/mingw, e.g. libxxx.dll.a
    opt = opt or {}
    if filename:startswith("lib") and filename:endswith(".dll.a") then
        return filename:sub(4, #filename - 6)
    end
    -- for macOS, libxxx.tbd
    if filename:startswith("lib") and filename:endswith(".tbd") then
        return filename:sub(4, #filename - 4)
    end
    local linkname, count = filename:gsub(target.filename("__pattern__", "static", {plat = opt.plat}):gsub("%.", "%%."):gsub("__pattern__", "(.+)") .. "$", "%1")
    if count == 0 then
        linkname, count = filename:gsub(target.filename("__pattern__", "shared", {plat = opt.plat}):gsub("%.", "%%."):gsub("__pattern__", "(.+)") .. "$", "%1")
    end
    -- in order to be compatible with mingw/windows library with .lib
    if count == 0 and opt.plat == "mingw" then
        linkname, count = filename:gsub(target.filename("__pattern__", "static", {plat = "windows"}):gsub("%.", "%%."):gsub("__pattern__", "(.+)") .. "$", "%1")
    end
    if count > 0 and linkname then
        return linkname
    end
    -- fallback to the generic unix library name, libxxx.a, libxxx.so, ..
    if filename:startswith("lib") then
        if filename:endswith(".a") or filename:endswith(".so") then
            return path.basename(filename:sub(4))
        end
    elseif filename:endswith(".so") or filename:endswith(".dylib") then
        -- for custom shared libraries name, xxx.so, xxx.dylib
        return filename
    end
    return nil
end

-- new a target instance
function target.new(...)
    return _instance.new(...)
end

-- return module
return target

