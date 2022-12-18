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
local instance_deps   = require("base/private/instance_deps")
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
    instance._NAME     = name
    instance._INFO     = info
    instance._CACHEID  = 1
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
    local key = ruleinst:name() .. (suffix and ("_" .. suffix) or "")
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
            deprecated.add(ruleinst:name() .. ".on_load", ruleinst:name() .. ".before_load")
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

-- get the copied files
function _instance:_copiedfiles(filetype, outputdir, pathfilter)

    -- no copied files?
    local copiedfiles = self:get(filetype)
    if not copiedfiles then return end

    -- get the extra information
    local extrainfo = table.wrap(self:get("__extra_" .. filetype))

    -- get the source paths and destinate paths
    local srcfiles = {}
    local dstfiles = {}
    local fileinfos = {}
    for _, copiedfile in ipairs(table.wrap(copiedfiles)) do

        -- get the root directory
        local rootdir, count = copiedfile:gsub("|.*$", ""):gsub("%(.*%)$", "")
        if count == 0 then
            rootdir = nil
        end
        if rootdir and rootdir:trim() == "" then
            rootdir = "."
        end

        -- remove '(' and ')'
        local srcpaths = copiedfile:gsub("[%(%)]", "")
        if srcpaths then

            -- get the source paths
            srcpaths = os.match(srcpaths)
            if srcpaths and #srcpaths > 0 then

                -- add the source copied files
                table.join2(srcfiles, srcpaths)

                -- the copied directory exists?
                if outputdir then

                    -- get the file info
                    local fileinfo = extrainfo[copiedfile] or {}

                    -- get the prefix directory
                    local prefixdir = fileinfo.prefixdir

                    -- add the destinate copied files
                    for _, srcpath in ipairs(srcpaths) do

                        -- get the destinate directory
                        local dstdir = outputdir
                        if prefixdir then
                            dstdir = path.join(dstdir, prefixdir)
                        end

                        -- the destinate file
                        local dstfile = nil
                        if rootdir then
                            dstfile = path.absolute(path.relative(srcpath, rootdir), dstdir)
                        else
                            dstfile = path.join(dstdir, path.filename(srcpath))
                        end
                        assert(dstfile)

                        -- modify filename
                        if fileinfo.filename then
                            dstfile = path.join(path.directory(dstfile), fileinfo.filename)
                        end

                        -- filter the destinate file path
                        if pathfilter then
                            dstfile = pathfilter(dstfile, fileinfo)
                        end

                        -- add it
                        table.insert(dstfiles, dstfile)
                        table.insert(fileinfos, fileinfo)
                    end
                end
            end
        end
    end
    return srcfiles, dstfiles, fileinfos
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

-- invalidate the previous cache
function _instance:_invalidate(name)
    self._CACHEID = self._CACHEID + 1
    self._POLICIES = nil
    -- we need flush the source files cache if target/files are modified, e.g. `target:add("files", "xxx.c")`
    if name == "files" then
        self._SOURCEFILES = nil
    elseif name == "deps" then
        self._DEPS = nil
        self._ORDERDEPS = nil
    end
end

-- build deps
function _instance:_build_deps()
    if target._project() then
        local instances = target._project().targets()
        self._DEPS      = self._DEPS or {}
        self._ORDERDEPS = self._ORDERDEPS or {}
        instance_deps.load_deps(self, instances, self._DEPS, self._ORDERDEPS, {self:name()})
    end
end

-- is loaded?
function _instance:_is_loaded()
    return self._LOADED
end

-- clone target, @note we can just call it in after_load()
function _instance:clone()
    if not self:_is_loaded() then
        os.raise("please call target:clone() in after_load().", self:name())
    end
    local instance = target.new(self:name(), self._INFO:clone())
    if self._DEPS then
        instance._DEPS = table.clone(self._DEPS)
    end
    if self._ORDERDEPS then
        instance._ORDERDEPS = table.clone(self._ORDERDEPS)
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
                local vs_conf = self:_visibility(extraconf[value])
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
        -- only get thr private values
        if bit.band(vs_required, vs_private) ~= 0 then
            return values
        end
    end
end

-- get values from target dependencies
function _instance:get_from_deps(name, opt)
    local values = {}
    local orderdeps = self:orderdeps()
    local total = #orderdeps
    for idx, _ in ipairs(orderdeps) do
        local dep = orderdeps[total + 1 - idx]
        local depinherit = self:extraconf("deps", dep:name(), "inherit")
        if depinherit == nil or depinherit then
            table.join2(values, dep:get(name, opt))
            table.join2(values, dep:get_from_opts(name, opt))
            table.join2(values, dep:get_from_pkgs(name, opt))
        end
    end
    return values
end

-- get values from target options with {interface|public = ...}
function _instance:get_from_opts(name, opt)
    local values = {}
    for _, opt_ in ipairs(self:orderopts(opt)) do
        table.join2(values, table.wrap(opt_:get(name)))
    end
    return values
end

-- get values from target packages with {interface|public = ...}
function _instance:get_from_pkgs(name, opt)
    local values = {}
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
            local components = table.wrap(pkg:components())
            for _, component_name in ipairs(table.join(pkg:components_orderlist(), "__base")) do
                if components_enabled:has(component_name) then
                    local info = components[component_name]
                    if info then
                        table.join2(values, info[name])
                    else
                        local components_str = table.concat(table.wrap(configinfo.components), ", ")
                        utils.warning("unknown component(%s) in add_packages(%s, {components = {%s}})", component_name, pkg:name(), components_str)
                    end
                end
            end
        -- get values instead of the builtin configs if exists extra package config
        -- e.g. `add_packages("xxx", {links = "xxx"})`
        elseif configinfo and configinfo[name] then
             table.join2(values, configinfo[name])
        else
            -- get values from the builtin package configs
            table.join2(values, pkg:get(name))
        end
    end
    return values
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
    self._NAME = name
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
    for _, v in ipairs(table.join(...)) do
        if v and plat == v then
            return true
        end
    end
end

-- the current target is belong to the given architectures?
function _instance:is_arch(...)
    local arch = self:arch()
    for _, v in ipairs(table.join(...)) do
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

    -- get version and build version
    local version = self:get("version")
    local version_build = nil
    if version then
        local version_extra = self:get("__extra_version")
        if version_extra then
            version_build = self._VERSION_BUILD
            if not version_build then
                version_build = table.wrap(version_extra[version]).build
                if type(version_build) == "string" then
                    version_build = os.date(version_build, os.time())
                    self._VERSION_BUILD = version_build
                end
            end
        end
    end
    return version, version_build
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
        return deps[name]
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
function _instance:orderdeps()
    if not self:_is_loaded() then
        os.raise("please call target:orderdeps() in after_load()!")
    end
    if self._DEPS == nil then
        self:_build_deps()
    end
    return self._ORDERDEPS
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
        orderules = {}
        local rulerefs = {}
        for _, r in table.orderpairs(rules) do
            instance_deps.sort_deps(rules, orderules, rulerefs, r)
        end
        self._ORDERULES = orderules
    end
    return orderules
end

-- get target rule from the given rule name
function _instance:rule(name)
    if self._RULES then
        return self._RULES[name]
    end
end

-- add rule
--
-- @note If a rule has the same name as a built-in rule,
-- it will be replaced in the target:rules() and target:orderules(), but will be not replaced globally in the project.rules()
function _instance:rule_add(r)
    self._RULES = self._RULES or {}
    self._RULES[r:name()] = r
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

-- is library target?
function _instance:is_library()
    return self:is_static() or self:is_shared() or self:is_headeronly()
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

-- get the enabled option
function _instance:opt(name)
    return self:opts()[name]
end

-- get the enabled options
function _instance:opts()

    -- attempt to get it from cache first
    if self._OPTS_ENABLED then
        return self._OPTS_ENABLED
    end

    -- load options if be enabled
    self._OPTS_ENABLED = {}
    for _, opt in ipairs(self:orderopts()) do
        self._OPTS_ENABLED[opt:name()] = opt
    end

    -- get it
    return self._OPTS_ENABLED
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

        -- load options if be enabled
        orderopts = {}
        for _, name in ipairs(table.wrap(self:get("options", opt))) do
            local opt_ = nil
            if config.get(name) then opt_ = option.load(name) end
            if opt_ then
                table.insert(orderopts, opt_)
            end
        end

        -- load options from packages if no require info, be compatible with the option package in (*.pkg)
        for _, name in ipairs(table.wrap(self:get("packages", opt))) do
            if not project_package.load(name) then
                local opt_ = nil
                if config.get(name) then opt_ = option.load(name) end
                if opt_ then
                    table.insert(orderopts, opt_)
                end
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
            local envs = pkg:get("envs")
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
    local extra_packages = self:get("__extra_packages")
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
    objectdir = path.join(objectdir, self:name())

    -- get root directory of target
    if opt and opt.root then
        return objectdir
    end

    -- append plat sub-directory
    local plat = self:plat()
    if plat then
        objectdir = path.join(objectdir, plat)
    end

    -- append arch sub-directory
    local arch = self:arch()
    if arch then
        objectdir = path.join(objectdir, arch)
    end

    -- append mode sub-directory
    local mode = config.get("mode")
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
    dependir = path.join(dependir, self:name())

    -- get root directory of target
    if opt and opt.root then
        return dependir
    end

    -- append plat sub-directory
    local plat = self:plat()
    if plat then
        dependir = path.join(dependir, plat)
    end

    -- append arch sub-directory
    local arch = self:arch()
    if arch then
        dependir = path.join(dependir, arch)
    end

    -- append mode sub-directory
    local mode = config.get("mode")
    if mode then
        dependir = path.join(dependir, mode)
    end
    return dependir
end

-- get the autogen files directory
function _instance:autogendir(opt)

    -- the autogen directory
    local autogendir = path.join(config.buildir(), ".gens", self:name())

    -- get root directory of target
    if opt and opt.root then
        return autogendir
    end

    -- append plat sub-directory
    local plat = self:plat()
    if plat then
        autogendir = path.join(autogendir, plat)
    end

    -- append arch sub-directory
    local arch = self:arch()
    if arch then
        autogendir = path.join(autogendir, arch)
    end

    -- append mode sub-directory
    local mode = config.get("mode")
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
    -- we need replace '..' to '__' in this case
    --
    if path.is_absolute(relativedir) and os.host() == "windows" then
        -- remove C:\\ and whitespaces
        -- e.g. C:\\Program Files (x64)\\xxx\Windows.h
        -- @see https://github.com/xmake-io/xmake/issues/3021
        relativedir = hash.uuid4(relativedir):gsub("%-", ""):lower()
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

        -- get build directory
        targetdir = config.buildir()

        -- append plat sub-directory
        local plat = self:plat()
        if plat then
            targetdir = path.join(targetdir, plat)
        end

        -- append arch sub-directory
        local arch = self:arch()
        if arch then
            targetdir = path.join(targetdir, arch)
        end

        -- append mode sub-directory
        local mode = config.get("mode")
        if mode then
            targetdir = path.join(targetdir, mode)
        end
    end
    return targetdir
end

-- get the target file name
function _instance:filename()

    -- no target file?
    if self:is_object() or self:is_phony() or self:is_headeronly() then
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
    local filename = target.filename(self:basename(), "symbol", {plat = self:plat(), arch = self:arch()})
    assert(filename)

    -- make the symbol file path
    return path.join(targetdir, filename)
end

-- get the script directory of xmake.lua
function _instance:scriptdir()
    return self:get("__scriptdir")
end

-- TODO get header directory (deprecated)
function _instance:headerdir()
    return self:get("headerdir") or config.buildir()
end

-- get configuration output directory
function _instance:configdir()
    return self:get("configdir") or config.buildir()
end

-- get run directory
function _instance:rundir()
    return baseoption.get("workdir") or self:get("rundir") or path.directory(self:targetfile())
end

-- get install directory
function _instance:installdir()

    -- get it from the cache
    local installdir = baseoption.get("installdir")
    if not installdir then

        -- DESTDIR: be compatible with https://www.gnu.org/prep/standards/html_node/DESTDIR.html
        installdir = self:get("installdir") or os.getenv("INSTALLDIR") or os.getenv("PREFIX") or os.getenv("DESTDIR") or platform.get("installdir")
        if installdir then
            installdir = installdir:trim()
        end
    end
    return installdir
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
                local r = target._project().rule(rulename) or rule.rule(rulename)
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
function _instance:fileconfig(sourcefile)

    -- get files config
    local filesconfig = self._FILESCONFIG
    if not filesconfig then
        filesconfig = {}
        for filepath, fileconfig in pairs(table.wrap(self:get("__extra_files"))) do

            -- match source files
            local results = os.match(filepath)
            if #results == 0 and not fileconfig.always_added then
                local sourceinfo = (self:get("__sourceinfo_files") or {})[filepath] or {}
                utils.warning("cannot match %s(%s).add_files(\"%s\") at %s:%d", self:type(), self:name(), filepath, sourceinfo.file or "", sourceinfo.line or -1)
            end

            -- process source files
            for _, file in ipairs(results) do
                if path.is_absolute(file) then
                    file = path.relative(file, os.projectdir())
                end
                filesconfig[file] = fileconfig
            end
            -- we also need support always_added, @see https://github.com/xmake-io/xmake/issues/1634
            if #results == 0 and fileconfig.always_added then
                filesconfig[filepath] = fileconfig
            end
        end
        self._FILESCONFIG = filesconfig
    end

    -- get file config
    return filesconfig[sourcefile]
end

-- set the config info to the given source file
function _instance:fileconfig_set(sourcefile, info)
    local filesconfig = self._FILESCONFIG or {}
    filesconfig[sourcefile] = info
    self._FILESCONFIG = filesconfig
end

-- add the config info to the given source file
function _instance:fileconfig_add(sourcefile, info)
    local filesconfig = self._FILESCONFIG or {}
    local fileconfig = filesconfig[sourcefile]
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
    self._FILESCONFIG = filesconfig
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
            local sourceinfo = (self:get("__sourceinfo_files") or {})[file] or {}
            utils.warning("cannot match %s(%s).%s_files(\"%s\") at %s:%d", self:type(), self:name(), (removed and "remove" or "add"), file, sourceinfo.file or "", sourceinfo.line or -1)
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
                local pattern = path.translate(removed_file:gsub("|.*$", ""))
                if pattern:sub(1, 2):find('%.[/\\]') then
                    pattern = pattern:sub(3)
                end
                pattern = path.pattern(pattern)
                if sourcefile:match(pattern) then
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
        filename = target.filename(path.filename(sourcefile), "object", {plat = self:plat(), arch = self:arch()})})
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
    table.sort(orderkeys) -- @note we need guarantee the order of objectfiles for depend.is_changed() and etc.
    for _, k in ipairs(orderkeys) do
        local sourcebatch = sourcebatches[k]
        table.join2(objectfiles, sourcebatch.objectfiles)
        batchcount = batchcount + 1
    end

    -- some object files may be repeat and appear link errors if multi-batches exists, so we need remove all repeat object files
    -- e.g. add_files("src/*.c", {rules = {"rule1", "rule2"}})
    local deduplicate = batchcount > 1

    -- get object files from all dependent targets (object kind)
    if self:orderdeps() then
        for _, dep in ipairs(self:orderdeps()) do
            if dep:kind() == "object" then
                table.join2(objectfiles, dep:objectfiles())
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

-- TODO get the header files, get("headers") (deprecated)
function _instance:headers(outputdir)
    return self:headerfiles(outputdir, {only_deprecated = true})
end

-- get the header files
--
-- default: get("headers") + get("headerfiles")
-- only_deprecated: get("headers")
--
function _instance:headerfiles(outputdir, opt)

    -- get header files?
    opt = opt or {}
    local headers = self:get("headers") -- TODO deprecated
    local only_deprecated = opt.only_deprecated
    if not only_deprecated then
       headers = table.join(headers or {}, self:get("headerfiles"))
       -- add_headerfiles("src/*.h", {install = false})
       -- @see https://github.com/xmake-io/xmake/issues/2577
       if opt.installonly then
           local installfiles = {}
           for _, headerfile in ipairs(table.wrap(headers)) do
               if self:extraconf("headerfiles", headerfile, "install") ~= false then
                   table.insert(installfiles, headerfile)
               end
           end
           headers = installfiles
       end
    end
    if not headers then
        return
    end

    -- get the installed header directory
    local headerdir = outputdir
    if not headerdir then
        if only_deprecated then
            headerdir = self:headerdir()
        elseif self:installdir() then
            headerdir = path.join(self:installdir(), "include")
        end
    end

    -- get the extra information
    local extrainfo = table.wrap(self:get("__extra_headerfiles"))

    -- get the source paths and destinate paths
    local srcheaders = {}
    local dstheaders = {}
    local srcheaders_removed = {}
    local removed_count = 0
    for _, header in ipairs(table.wrap(headers)) do

        -- mark as removed files?
        local removed = false
        local prefix = "__remove_"
        if header:startswith(prefix) then
            header = header:sub(#prefix + 1)
            removed = true
        end

        -- get the root directory
        local rootdir, count = header:gsub("|.*$", ""):gsub("%(.*%)$", "")
        if count == 0 then
            rootdir = nil
        end
        if rootdir and rootdir:trim() == "" then
            rootdir = "."
        end

        -- remove '(' and ')' first
        local srcpaths = header:gsub("[%(%)]", "")
        if srcpaths then

            -- get the source paths
            srcpaths = os.match(srcpaths)
            if srcpaths then
                if removed then
                    removed_count = removed_count + #srcpaths
                    table.join2(srcheaders_removed, srcpaths)
                else
                    -- add the source headers
                    table.join2(srcheaders, srcpaths)

                    -- get the destinate directories if the install directory exists
                    if headerdir then
                        local prefixdir = (extrainfo[header] or {}).prefixdir
                        for _, srcpath in ipairs(srcpaths) do
                            local dstdir = headerdir
                            if prefixdir then
                                dstdir = path.join(dstdir, prefixdir)
                            end
                            local dstheader = nil
                            if rootdir then
                                dstheader = path.absolute(path.relative(srcpath, rootdir), dstdir)
                            else
                                dstheader = path.join(dstdir, path.filename(srcpath))
                            end
                            table.insert(dstheaders, dstheader)
                        end
                    end
                end
            end
        end
    end

    -- remove all header files which need be removed
    if removed_count > 0 then
        table.remove_if(srcheaders, function (i, srcheader)
            for _, removed_file in ipairs(srcheaders_removed) do
                local pattern = path.translate(removed_file:gsub("|.*$", ""))
                if pattern:sub(1, 2):find('%.[/\\]') then
                    pattern = pattern:sub(3)
                end
                pattern = path.pattern(pattern)
                if srcheader:match(pattern) then
                    if i <= #dstheaders then
                        table.remove(dstheaders, i)
                    end
                    return true
                end
            end
        end)
    end
    return srcheaders, dstheaders
end

-- get the configuration files
function _instance:configfiles(outputdir)
    return self:_copiedfiles("configfiles", outputdir or self:configdir(), function (dstpath, fileinfo)
            if dstpath:endswith(".in") then
                dstpath = dstpath:sub(1, -4)
            end
            return dstpath
        end)
end

-- get the install files
function _instance:installfiles(outputdir)
    return self:_copiedfiles("installfiles", outputdir or self:installdir())
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
        relativedir = relativedir:gsub(":[\\/]*", '\\') -- replace C:\xxx\ => C\xxx\
    end

    -- originfile: project/build/.objs/xxxx/../../xxx.c will be out of range for objectdir
    --
    -- we need replace '..' to '__' in this case
    --
    relativedir = relativedir:gsub("%.%.", "__")

    -- make dependent file
    -- full file name(not base) to avoid name-clash of original file
    return path.join(self:dependir(), relativedir, path.filename(originfile) .. ".d")
end

-- get the dependent include files
function _instance:dependfiles()

    -- get source batches
    local sourcebatches, modified = self:sourcebatches()

    -- cached? return it directly
    if self._DEPENDFILES and not modified then
        return self._DEPENDFILES
    end

    -- get dependent files from source batches
    local dependfiles = {}
    for _, sourcebatch in pairs(self:sourcebatches()) do
        table.join2(dependfiles, sourcebatch.dependfiles)
    end

    -- cache it
    self._DEPENDFILES = dependfiles

    -- ok?
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
        for _, sourcebatch in table.orderpairs(self:sourcebatches()) do
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
    local result = nil
    if type(script) == "function" then
        result = script
    elseif type(script) == "table" then

        -- get plat and arch
        local plat = self:plat()
        local arch = self:arch()

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

-- TODO get the config header version (deprecated)
function _instance:configversion()

    -- get the config version and build version
    local version = nil
    local buildversion = nil
    local configheader = self:get("config_header")
    local configheader_extra = self:get("__extra_config_header")
    if type(configheader_extra) == "table" then
        version      = table.wrap(configheader_extra[configheader]).version
        buildversion = self._CONFIGHEADER_BUILDVERSION
        if not buildversion then
            buildversion = table.wrap(configheader_extra[configheader]).buildversion
            if buildversion then
                buildversion = os.date(buildversion, os.time())
            end
            self._CONFIGHEADER_BUILDVERSION = buildversion
        end
    end

    -- ok?
    return version, buildversion
end

-- get the config header prefix
function _instance:configprefix()

    -- get the config prefix
    local configprefix = nil
    local configheader = self:get("config_header")
    local configheader_extra = self:get("__extra_config_header")
    if type(configheader_extra) == "table" then
        configprefix = table.wrap(configheader_extra[configheader]).prefix
    end
    return configprefix
end

-- get the config header files (deprecated)
function _instance:configheader(outputdir)

    -- get config header
    local configheader = self:get("config_header")
    if not configheader then
        return
    end

    -- get the root directory
    local rootdir, count = configheader:gsub("|.*$", ""):gsub("%(.*%)$", "")
    if count == 0 then
        rootdir = nil
    end
    if rootdir and rootdir:trim() == "" then
        rootdir = "."
    end

    -- remove '(' and ')'
    configheader = configheader:gsub("[%(%)]", "")

    -- get the output header
    local outputheader = nil
    if outputdir then
        if rootdir then
            outputheader = path.absolute(path.relative(configheader, rootdir), outputdir)
        else
            outputheader = path.join(outputdir, path.filename(configheader))
        end
    end

    -- ok
    return configheader, outputheader
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

    -- init cache
    self._PCOUTPUTFILES = self._PCOUTPUTFILES or {}

    -- get it from the cache first
    local pcoutputfile = self._PCOUTPUTFILES[langkind]
    if pcoutputfile then
        return pcoutputfile
    end

    -- get the precompiled header file in the object directory
    local pcheaderfile = self:pcheaderfile(langkind)
    if pcheaderfile then

        -- is gcc?
        local is_gcc = false
        local _, toolname = self:tool(langkind == "c" and "cc" or "cxx")
        if toolname and (toolname == "gcc" or toolname == "gxx") then
            is_gcc = true
        end

        -- make precompiled output file
        --
        -- @note gcc has not -include-pch option to set the pch file path
        --
        pcoutputfile = self:objectfile(pcheaderfile)
        pcoutputfile = path.join(path.directory(pcoutputfile), path.basename(pcoutputfile) .. (is_gcc and ".gch" or ".pch"))

        -- save to cache
        self._PCOUTPUTFILES[langkind] = pcoutputfile
        return pcoutputfile
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

        -- load target toolchains
        local target_toolchains = self:get("toolchains")
        if target_toolchains then
            toolchains = {}
            for _, name in ipairs(table.wrap(target_toolchains)) do
                local toolchain_opt = table.copy(self:extraconf("toolchains", name))
                toolchain_opt.arch = self:arch()
                toolchain_opt.plat = self:plat()
                local toolchain_inst, errors = toolchain.load(name, toolchain_opt)
                -- attempt to load toolchain from project
                if not toolchain_inst and target._project() then
                    toolchain_inst = target._project().toolchain(name, toolchain_opt)
                end
                if not toolchain_inst then
                    os.raise(errors)
                end
                table.insert(toolchains, toolchain_inst)
            end
        else
            -- load platform toolchains
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
        os.raise("we cannot get tool(%s) before target(%s) is loaded, maybe it is called on_load(), please call it in on_config().", toolkind, self:name())
    end
    return toolchain.tool(self:toolchains(), toolkind, {cachekey = "target_" .. self:name(), plat = self:plat(), arch = self:arch(),
                                                        before_get = function()
        -- get program from set_toolchain/set_tools (deprecated)
        local toolname
        local program = self:get("toolset." .. toolkind) or self:get("toolchain." .. toolkind)
        if not program then
            local tools = self:get("tools") -- TODO: deprecated
            if tools then
                program = tools[toolkind]
            end
        end
        -- get program from `xmake f --cc`
        if not program and not self:get("toolchains") then
            program = config.get(toolkind)
        end

        -- contain toolname? parse it, e.g. 'gcc@xxxx.exe'
        -- https://github.com/xmake-io/xmake/issues/1361
        if program and not toolname then
            local pos = program:find('@', 1, true)
            if pos then
                -- we need ignore valid path with `@`, e.g. /usr/local/opt/go@1.17/bin/go
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
    return toolchain.toolconfig(self:toolchains(), name, {cachekey = "target_" .. self:name(), plat = self:plat(), arch = self:arch(),
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
        for _, v in ipairs(table.join(...)) do
            if v and toolname:find("^" .. v:gsub("%-", "%%-") .. "$") then
                return true
            end
        end
    end
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
            -- target.add_xxx
        ,   "target.add_deps"
        ,   "target.add_rules"
        ,   "target.add_options"
        ,   "target.add_packages"
        ,   "target.add_imports"
        ,   "target.add_languages"
        ,   "target.add_vectorexts"
        ,   "target.add_toolchains"
        }
    ,   keyvalues =
        {
            -- target.set_xxx
            "target.set_values"
        ,   "target.set_configvar"
        ,   "target.set_runenv"
        ,   "target.set_toolchain" -- TODO: deprecated
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
        ,   "target.set_configdir"
        ,   "target.set_installdir"
        ,   "target.set_rundir"
            -- target.add_xxx
        ,   "target.add_files"
        ,   "target.add_cleanfiles"
        ,   "target.add_configfiles"
        ,   "target.add_installfiles"
            -- target.del_xxx (deprecated)
        ,   "target.del_files"
            -- target.remove_xxx
        ,   "target.remove_files"
        ,   "target.remove_headerfiles"
        }
    ,   dictionary =
        {
            -- target.set_xxx
            "target.set_tools" -- TODO: deprecated
        ,   "target.add_tools" -- TODO: deprecated
        }
    ,   script =
        {
            -- target.on_xxx
            "target.on_run"
        ,   "target.on_load"
        ,   "target.on_config"
        ,   "target.on_link"
        ,   "target.on_build"
        ,   "target.on_build_file"
        ,   "target.on_build_files"
        ,   "target.on_clean"
        ,   "target.on_package"
        ,   "target.on_install"
        ,   "target.on_uninstall"
            -- target.before_xxx
        ,   "target.before_run"
        ,   "target.before_link"
        ,   "target.before_build"
        ,   "target.before_build_file"
        ,   "target.before_build_files"
        ,   "target.before_clean"
        ,   "target.before_package"
        ,   "target.before_install"
        ,   "target.before_uninstall"
            -- target.after_xxx
        ,   "target.after_run"
        ,   "target.after_load"
        ,   "target.after_link"
        ,   "target.after_build"
        ,   "target.after_build_file"
        ,   "target.after_build_files"
        ,   "target.after_clean"
        ,   "target.after_package"
        ,   "target.after_install"
        ,   "target.after_uninstall"
        }
    }
end

-- get the filename from the given target name and kind
function target.filename(targetname, targetkind, opt)

    -- check
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
    return count > 0 and linkname or nil
end

-- new a target instance
function target.new(...)
    return _instance.new(...)
end

-- return module
return target

