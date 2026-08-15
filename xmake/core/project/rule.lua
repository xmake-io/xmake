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
-- Copyright (C) 2015-present, Xmake Open Source Community.
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
local select_script  = require("base/private/select_script")
local addon          = require("package/addon")
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
    instance_deps.load_deps(self, instances, self._DEPS, self._ORDERDEPS, {self:fullname()})

    -- compatible with `add_deps("foo", {order = true})`
    local plaindeps = self:get("deps")
    if plaindeps then
        for _, depname in ipairs(table.wrap(plaindeps)) do
            if self:extraconf("deps", depname, "order") then
                self:add("orders", depname, self:name())
                utils.warning("add_deps(%s, {order = true}) has been deprecated, please use `add_orders(%s, %s) instead of it`",
                    depname, depname, self:name())
            end
        end
    end
end

-- clone rule
function _instance:clone()
    local instance = rule.new(self:fullname(), self._INFO:clone())
    instance._DEPS = self._DEPS
    instance._ORDERDEPS = self._ORDERDEPS
    instance._PACKAGE = self._PACKAGE
    return instance
end

-- get the rule info value
--
-- @param name  the info name
-- @return      the info value
--
function _instance:get(name)
    return self._INFO:get(name)
end

-- set the value to the rule info
--
-- @param name  the info name
-- @param ...   the values
--
function _instance:set(name, ...)
    self._INFO:apival_set(name, ...)
    self:_invalidate(name)
end

-- add the value to the rule info
--
-- @param name  the info name
-- @param ...   the values to add
--
function _instance:add(name, ...)
    self._INFO:apival_add(name, ...)
    self:_invalidate(name)
end

-- get the extra configuration
--
-- @param name  the config name
-- @param item  the config item
-- @param key   the config key (optional)
-- @return      the extra config value
--
function _instance:extraconf(name, item, key)
    return self._INFO:extraconf(name, item, key)
end

-- set the extra configuration
function _instance:extraconf_set(name, item, key, value)
    return self._INFO:extraconf_set(name, item, key, value)
end

-- get the rule name
--
-- @return      the rule name string
--
function _instance:name()
    return self._NAME
end

-- set the rule name
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

-- get the rule script function (on_build, on_install, etc.)
--
-- @param name     the script name, e.g. "build", "install", "clean"
-- @param generic  use generic script if platform-specific not found?
-- @return         the script function
--
function _instance:script(name, generic)

    -- get script
    local script = self:get(name)
    local result = select_script(script, {plat = config.get("plat"), arch = config.get("arch")}) or generic

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

-- the rule directories of the installed addons, e.g. ~/.xmake/addons/<name>/<version>/rules
function rule._addon_directories()
    return addon.payloadinfos("rules")
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
    ,   groups =
        {
            -- rule.add_xxx
           "rule.add_orders"
        }
    ,   script =
        {
            -- rule.on_xxx
            "rule.on_run"
        ,   "rule.on_test"
        ,   "rule.on_load"
        ,   "rule.on_config"
        ,   "rule.on_prepare"
        ,   "rule.on_prepare_file"
        ,   "rule.on_prepare_files"
        ,   "rule.on_link"
        ,   "rule.on_build"
        ,   "rule.on_build_file"
        ,   "rule.on_build_files"
        ,   "rule.on_clean"
        ,   "rule.on_package"
        ,   "rule.on_install"
        ,   "rule.on_uninstall"
        ,   "rule.on_preparecmd"
        ,   "rule.on_preparecmd_file"
        ,   "rule.on_preparecmd_files"
        ,   "rule.on_linkcmd"
        ,   "rule.on_buildcmd"
        ,   "rule.on_buildcmd_file"
        ,   "rule.on_buildcmd_files"
        ,   "rule.on_installcmd"
        ,   "rule.on_uninstallcmd"
            -- rule.before_xxx
        ,   "rule.before_run"
        ,   "rule.before_test"
        ,   "rule.before_load"
        ,   "rule.before_config"
        ,   "rule.before_prepare"
        ,   "rule.before_prepare_file"
        ,   "rule.before_prepare_files"
        ,   "rule.before_link"
        ,   "rule.before_build"
        ,   "rule.before_build_file"
        ,   "rule.before_build_files"
        ,   "rule.before_clean"
        ,   "rule.before_package"
        ,   "rule.before_install"
        ,   "rule.before_uninstall"
        ,   "rule.before_preparecmd"
        ,   "rule.before_preparecmd_file"
        ,   "rule.before_preparecmd_files"
        ,   "rule.before_linkcmd"
        ,   "rule.before_buildcmd"
        ,   "rule.before_buildcmd_file"
        ,   "rule.before_buildcmd_files"
        ,   "rule.before_installcmd"
        ,   "rule.before_uninstallcmd"
            -- rule.after_xxx
        ,   "rule.after_run"
        ,   "rule.after_test"
        ,   "rule.after_load"
        ,   "rule.after_config"
        ,   "rule.after_prepare"
        ,   "rule.after_prepare_file"
        ,   "rule.after_prepare_files"
        ,   "rule.after_link"
        ,   "rule.after_build"
        ,   "rule.after_build_file"
        ,   "rule.after_build_files"
        ,   "rule.after_clean"
        ,   "rule.after_package"
        ,   "rule.after_install"
        ,   "rule.after_uninstall"
        ,   "rule.after_preparecmd"
        ,   "rule.after_preparecmd_file"
        ,   "rule.after_preparecmd_files"
        ,   "rule.after_linkcmd"
        ,   "rule.after_buildcmd"
        ,   "rule.after_buildcmd_file"
        ,   "rule.after_buildcmd_files"
        ,   "rule.after_installcmd"
        ,   "rule.after_uninstallcmd"
        }
    }
end

-- new a rule instance
function rule.new(name, info, opt)
    opt = opt or {}
    local instance = table.inherit(_instance)
    if name then
        instance:name_set(name)
    end
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
            local depname = depname
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
            local depname = depname
            if depname:startswith("@") and not depname:find("/", 1, true) then
                depname = "@" .. opt.package:name() .. "/" .. depname:sub(2)
                instance:extraconf_set("deps", depname, extraconf)
            end
        end
    end
    return instance
end

-- get the file which declares the given rule, e.g. c.build -> <rulesdir>/c++/xmake.lua
--
-- most of the rule names match their directory name, so we only need it for the few
-- which do not, e.g. c.build, win.sdk.resource, and we get them by scanning the rule
-- declarations, which is much cheaper than interpreting all the rule files
--
function rule._rulefile(name)
    local rulefiles = rule._RULEFILES
    if rulefiles == nil then

        -- @note we only limit the fast paths, a rule file which is nested deeper than this
        -- is still found by the full load, @see rule.rules
        local maxrecursion = 4
        rulefiles = {}
        for _, dir in ipairs(rule._directories()) do
            for _, filepath in ipairs(os.files(path.join(dir, "**/xmake.lua"), {recursion = maxrecursion})) do
                local content = io.readfile(filepath)
                if content then
                    for rulename in content:gmatch("rule%s*%(%s*\"(.-)\"%s*%)") do
                        rulefiles[rulename] = filepath
                    end
                end
            end
        end
        rule._RULEFILES = rulefiles
    end
    return rulefiles[name]
end

-- load the rules which may provide the given rule name
--
-- there are hundreds of builtin rules, but a project only uses a few of them,
-- so we do not load all of them, we only load the group which may provide it,
-- e.g. mode.debug -> <rulesdir>/mode/**/xmake.lua
--
function rule._load_ondemand(name)

    -- it has been loaded with another group? e.g. c.build.pcheader comes with the c++ group
    local loaded = rule._LOADED
    if loaded == nil then
        loaded = {}
        rule._LOADED = loaded
    end
    local instance = loaded[name]
    if instance then
        return instance
    end

    local groups = rule._GROUPS
    if groups == nil then
        groups = {}
        rule._GROUPS = groups
    end

    -- the rules of an addon are always referenced with its name,
    -- e.g. add_rules("@addon/esp32/flash"), so we only load this addon
    local maxrecursion = 4
    local groupkey, files, opt
    if name:startswith("@addon/") then
        local referenceinfo = addon.resolve_reference(name, "/", "rules")
        if not referenceinfo then
            return
        end
        groupkey = "@addon/" .. referenceinfo.addon
        files = os.files(path.join(referenceinfo.dir, "**/xmake.lua"), {recursion = maxrecursion})
        opt = {prefix = groupkey .. "/"}
    else
        -- the group is the first part of the rule name, and it's usually the directory
        -- name of its rules, e.g. mode.debug -> <rulesdir>/mode
        groupkey = name:split(".", {plain = true})[1]
        files = {}
        for _, dir in ipairs(rule._directories()) do
            local groupdir = path.join(dir, groupkey)
            table.join2(files, os.files(path.join(groupdir, "xmake.lua")))
            table.join2(files, os.files(path.join(groupdir, "**/xmake.lua"), {recursion = maxrecursion}))
        end

        -- the rule name does not match its directory name? we can only get its file
        -- from the rule declarations, e.g. c.build -> <rulesdir>/c++/xmake.lua
        if #files == 0 then
            local rulefile = rule._rulefile(name)
            if not rulefile then
                return
            end
            groupkey = rulefile
            files = {rulefile}
        end
    end

    if not groups[groupkey] then
        local ruleinfos = {}
        rule._load_rulefiles(ruleinfos, files, opt)
        for rulename, ruleinfo in pairs(ruleinfos) do
            loaded[rulename] = rule.new(rulename, ruleinfo)
        end
        groups[groupkey] = true
    end
    return loaded[name]
end

-- report the missing addon of the given rule reference, e.g. add_rules("@addon/esp32/flash")
--
-- it's either not installed at all, or it's installed but does not provide this rule
--
function rule._raise_addon_notfound(name)
    local referenceinfo, errors = addon.resolve_reference(name, "/", "rules")
    if errors then
        os.raise(errors)
    end
    os.raise("rule(%s) not found!\nplease install the addon which provides it first: xmake addon --install %s",
        name, referenceinfo and referenceinfo.addon or "<addon>")
end

-- clear the loaded rules, e.g. some addons may be installed just now
function rule.clear()
    rule._RULES = nil
    rule._GROUPS = nil
    rule._LOADED = nil
    rule._RULEFILES = nil
end

-- get the given global rule
--
-- @param name  the rule name, the rules of the installed addons need the
--              `@addon/<addon>/` prefix, e.g. "@addon/esp32/flash"
--
function rule.rule(name)
    local instance
    if rule._RULES then
        -- all the rules have been loaded, e.g. rule.rules()
        instance = rule._RULES[name]
    else
        -- we only load the rules which may provide it
        instance = rule._load_ondemand(name)
        if instance == nil then
            -- @note the rule name may not match its directory name, so we need
            -- to load all the rules to be sure that it does not exist
            instance = rule.rules()[name]
        end
    end
    if instance == nil and name:startswith("@addon/") then
        rule._raise_addon_notfound(name)
    end
    return instance
end

-- load the rules from the given directory
function rule._load_rules(ruleinfos, dir, opt)
    -- @note we may load a group directory directly, e.g. <rulesdir>/mode/xmake.lua
    rule._load_rulefiles(ruleinfos, table.join(os.files(path.join(dir, "xmake.lua")),
                                               os.files(path.join(dir, "**/xmake.lua"))), opt)
end

-- load the rules from the given files
function rule._load_rulefiles(ruleinfos, files, opt)
    opt = opt or {}
    if files then
        for _, filepath in ipairs(files) do
            local results, errors = rule._load(filepath)
            if results then
                for rulename, ruleinfo in pairs(results) do
                    -- the addon rules are always referenced with the addon name,
                    -- e.g. add_rules("@addon/esp32/flash")
                    local fullname = (opt.prefix or "") .. rulename
                    if opt.prefix and ruleinfos[fullname] == nil then
                        -- the addon rules can depend on the other rules of the same addon,
                        -- e.g. add_deps("@self/base") -> add_deps("@addon/<addon>/base")
                        rule._replace_selfdeps(ruleinfo, opt.prefix)
                    end
                    ruleinfos[fullname] = ruleinfo
                end
            else
                os.raise(errors)
            end
        end
    end
end

-- replace the `@self/` dependencies of the addon rules with the full names
function rule._replace_selfdeps(ruleinfo, prefix)
    local deps = {}
    local replace = function (depname)
        if depname:startswith("@self/") then
            return prefix .. depname:sub(#"@self/" + 1)
        end
        return depname
    end
    for _, depname in ipairs(table.wrap(ruleinfo:get("deps"))) do
        table.insert(deps, replace(depname))
    end
    if #deps > 0 then
        ruleinfo:set("deps", table.unwrap(deps))
    end
    for depname, extraconf in pairs(table.wrap(ruleinfo:extraconf("deps"))) do
        local newname = replace(depname)
        if newname ~= depname then
            ruleinfo:extraconf_set("deps", newname, extraconf)
        end
    end
end

-- get global rules
function rule.rules()
    local rules = rule._RULES
    if rules == nil then
        local ruleinfos = {}
        for _, dir in ipairs(rule._directories()) do
            rule._load_rules(ruleinfos, dir)
        end
        for _, addoninfo in ipairs(rule._addon_directories()) do
            rule._load_rules(ruleinfos, addoninfo.dir, {prefix = "@addon/" .. addoninfo.name .. "/"})
        end

        -- make rule instances
        --
        -- @note we reuse the rules which have been loaded on demand,
        -- otherwise we would have two instances of the same rule
        local loaded = rule._LOADED or {}
        rules = {}
        for rulename, ruleinfo in pairs(ruleinfos) do
            rules[rulename] = loaded[rulename] or rule.new(rulename, ruleinfo)
        end
        rule._RULES = rules
    end
    return rules
end

-- return module
return rule
