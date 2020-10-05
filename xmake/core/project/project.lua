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

-- define module: project
local project = project or {}

-- load modules
local os                    = require("base/os")
local io                    = require("base/io")
local path                  = require("base/path")
local task                  = require("base/task")
local utils                 = require("base/utils")
local table                 = require("base/table")
local global                = require("base/global")
local process               = require("base/process")
local deprecated            = require("base/deprecated")
local interpreter           = require("base/interpreter")
local rule                  = require("project/rule")
local target                = require("project/target")
local config                = require("project/config")
local option                = require("project/option")
local policy                = require("project/policy")
local requireinfo           = require("project/requireinfo")
local deprecated_project    = require("project/deprecated/project")
local package               = require("package/package")
local platform              = require("platform/platform")
local toolchain             = require("tool/toolchain")
local language              = require("language/language")
local sandbox_os            = require("sandbox/modules/os")
local sandbox_module        = require("sandbox/modules/import/core/sandbox/module")

-- register project to platform
platform._PROJECT = project

-- the current os is belong to the given os?
function project._api_is_os(interp, ...)

    -- get the current os
    local os = platform.os()
    if not os then return false end

    -- exists this os?
    for _, o in ipairs(table.join(...)) do
        if o and type(o) == "string" and o == os then
            return true
        end
    end
end

-- the current mode is belong to the given modes?
function project._api_is_mode(interp, ...)
    return config.is_mode(...)
end

-- the current platform is belong to the given platforms?
function project._api_is_plat(interp, ...)
    return config.is_plat(...)
end

-- the current platform is belong to the given architectures?
function project._api_is_arch(interp, ...)
    return config.is_arch(...)
end

-- the current kind is belong to the given kinds?
function project._api_is_kind(interp, ...)

    -- get the current kind
    local kind = config.get("kind")
    if not kind then return false end

    -- exists this kind?
    for _, k in ipairs(table.join(...)) do
        if k and type(k) == "string" and k == kind then
            return true
        end
    end
end

-- the current config is belong to the given config values?
function project._api_is_config(interp, name, ...)
    return config.is_value(name, ...)
end

-- some configs are enabled?
function project._api_has_config(interp, ...)
    return config.has(...)
end

-- some packages are enabled?
function project._api_has_package(interp, ...)
    -- only for loading targets
    local requires = project._REQUIRES
    if requires then
        for _, name in ipairs(table.join(...)) do
            local pkg = requires[name]
            if pkg and pkg:enabled() then
                return true
            end
        end
    end
end

-- get config from the given name
function project._api_get_config(interp, name)
    return config.get(name)
end

-- add module directories
function project._api_add_moduledirs(interp, ...)
    sandbox_module.add_directories(...)
end

-- add plugin directories load all plugins from the given directories
function project._api_add_plugindirs(interp, ...)

    -- get all directories
    local plugindirs = {}
    local dirs = table.join(...)
    for _, dir in ipairs(dirs) do
        table.insert(plugindirs, dir .. "/*")
    end

    -- add all plugins
    interp:api_builtin_includes(plugindirs)
end

-- add platform directories
function project._api_add_platformdirs(interp, ...)
    platform.add_directories(...)
end

-- load the project file
function project._load(force, disable_filter)

    -- has already been loaded?
    if project._INFO and not force then
        return true
    end

    -- enter the project directory
    local oldir, errors = os.cd(os.projectdir())
    if not oldir then
        return false, errors
    end

    -- get interpreter
    local interp = project.interpreter()

    -- load script
    local ok, errors = interp:load(project.rootfile(), {on_load_data = function (data)
            local xmakerc_file = project.rcfile()
            if xmakerc_file and os.isfile(xmakerc_file) then
                local rcdata = io.readfile(xmakerc_file)
                if rcdata then
                    data = rcdata .. "\n" .. data
                end
            end
            return data
        end})
    if not ok then
        return false, (errors or "load project file failed!")
    end

    -- load the root info of the project
    local rootinfo, errors = project._load_scope("root", true, not disable_filter)
    if not rootinfo then
        return false, errors
    end

    -- load the root info of the target
    local rootinfo_target, errors = project._load_scope("root.target", true, not disable_filter)
    if not rootinfo_target then
        return false, errors
    end

    -- save the root info
    for name, value in pairs(rootinfo_target:info()) do
        rootinfo:set("target." .. name, value)
    end
    project._INFO = rootinfo

    -- leave the project directory
    oldir, errors = os.cd(oldir)
    if not oldir then
        return false, errors
    end
    return true
end

-- load deps for instance: e.g. option, target and rule
--
-- e.g.
--
-- a.deps = b
-- b.deps = c
--
-- orderdeps: c -> b -> a
--
function project._load_deps(instance, instances, deps, orderdeps)

    -- get dep instances
    for _, dep in ipairs(table.wrap(instance:get("deps"))) do
        local depinst = instances[dep]
        if depinst then
            project._load_deps(depinst, instances, deps, orderdeps)
            if not deps[dep] then
                deps[dep] = depinst
                table.insert(orderdeps, depinst)
            end
        end
    end
end

-- load scope from the project file
function project._load_scope(scope_kind, remove_repeat, enable_filter)

    -- enter the project directory
    local oldir, errors = os.cd(os.projectdir())
    if not oldir then
        return nil, errors
    end

    -- get interpreter
    local interp = project.interpreter()

    -- load scope
    local results, errors = interp:make(scope_kind, remove_repeat, enable_filter)
    if not results then
        return nil, errors
    end

    -- leave the project directory
    oldir, errors = os.cd(oldir)
    if not oldir then
        return nil, errors
    end
    return results
end

-- load tasks
function project._load_tasks()

    -- the project file is not found?
    if not os.isfile(project.rootfile()) then
        return {}, nil
    end

    -- load the project file first and disable filter
    local ok, errors = project._load(true, true)
    if not ok then
        return nil, errors
    end

    -- load the tasks from the the project file
    local results, errors = project._load_scope("task", true, true)
    if not results then
       return nil, errors or "load project tasks failed!"
    end

    -- bind tasks for menu with an sandbox instance
    local ok, errors = task._bind(results, project.interpreter())
    if not ok then
        return nil, errors
    end

    -- make task instances
    local tasks = {}
    for taskname, taskinfo in pairs(results) do
        tasks[taskname] = task.new(taskname, taskinfo)
    end
    return tasks
end

-- load rules
function project._load_rules()

    -- load the project file first if has not been loaded?
    local ok, errors = project._load()
    if not ok then
        return nil, errors
    end

    -- load the rules from the the project file
    local results, errors = project._load_scope("rule", true, true)
    if not results then
        return nil, errors
    end

    -- make rule instances
    local rules = {}
    for rulename, ruleinfo in pairs(results) do
        rules[rulename] = rule.new(rulename, ruleinfo)
    end

    -- load rule deps
    local instances = table.join(rule.rules(), rules)
    for _, instance in pairs(instances)  do
        instance._DEPS      = instance._DEPS or {}
        instance._ORDERDEPS = instance._ORDERDEPS or {}
        project._load_deps(instance, instances, instance._DEPS, instance._ORDERDEPS)
    end
    return rules
end

-- load toolchains
function project._load_toolchains()

    -- load the project file first if has not been loaded?
    local ok, errors = project._load()
    if not ok then
        return nil, errors
    end

    -- load the toolchain from the the project file
    local results, errors = project._load_scope("toolchain", true, true)
    if not results then
        return nil, errors
    end

    -- make toolchain instances
    local toolchains = {}
    for toolchain_name, toolchain_info in pairs(results) do
        toolchains[toolchain_name] = toolchain.new(toolchain_name, toolchain_info)
    end
    return toolchains
end

-- load targets
function project._load_targets()

    -- load all requires first and reload the project file to ensure has_package() works for targets
    local requires = project.requires()
    local ok, errors = project._load(true)
    if not ok then
        return nil, errors
    end

    -- load targets
    local results, errors = project._load_scope("target", true, true)
    if not results then
        return nil, errors
    end

    -- make targets
    local targets = {}
    for targetname, targetinfo in pairs(results) do
        local t = target.new(targetname, targetinfo, project)
        if t and (t:get("enabled") == nil or t:get("enabled") == true) then
            targets[targetname] = t
        end
    end

    -- load and attach target deps, rules and packages
    for _, t in pairs(targets) do

        -- load deps
        t._DEPS      = t._DEPS or {}
        t._ORDERDEPS = t._ORDERDEPS or {}
        project._load_deps(t, targets, t._DEPS, t._ORDERDEPS)

        -- load rules from target and language
        --
        -- e.g.
        --
        -- a.deps = b
        -- b.deps = c
        --
        -- orderules: c -> b -> a
        --
        t._RULES      = t._RULES or {}
        t._ORDERULES  = t._ORDERULES or {}
        local rulenames = {}
        local extensions = {}
        table.join2(rulenames, t:get("rules"))
        for _, sourcefile in ipairs(table.wrap(t:get("files"))) do
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
            local r = project.rule(rulename) or rule.rule(rulename)
            if r then
                t._RULES[rulename] = r
                for _, deprule in ipairs(r:orderdeps()) do
                    local name = deprule:name()
                    if not t._RULES[name] then
                        t._RULES[name] = deprule
                        table.insert(t._ORDERULES, deprule)
                    end
                end
                table.insert(t._ORDERULES, r)
            else
                return nil, string.format("unknown rule(%s) in target(%s)!", rulename, t:name())
            end
        end

        -- load packages
        t._PACKAGES = t._PACKAGES or {}
        for _, packagename in ipairs(table.wrap(t:get("packages"))) do
            local p = requires[packagename]
            if p then
                table.insert(t._PACKAGES, p)
            end
        end

        -- load toolchains
        local toolchains = t:get("toolchains")
        if toolchains then
            t._TOOLCHAINS = {}
            for _, name in ipairs(table.wrap(toolchains)) do
                local toolchain_inst, errors = toolchain.load(name, t:extraconf("toolchains", name))
                -- attempt to load toolchain from project
                if not toolchain_inst then
                    toolchain_inst = project.toolchain(name)
                end
                if not toolchain_inst then
                    return nil, errors
                end
                table.insert(t._TOOLCHAINS, toolchain_inst)
            end
        end
    end

    -- sort targets for all deps
    local targetrefs = {}
    local ordertargets = {}
    for _, t in pairs(targets) do
        project._sort_targets(targets, ordertargets, targetrefs, t)
    end

    -- do load for each target
    local ok = false
    for _, t in ipairs(ordertargets) do
        ok, errors = t:_load()
        if not ok then
            break
        end
    end

    -- do load failed?
    if not ok then
        return nil, nil, errors
    end
    return targets, ordertargets
end

-- load options
function project._load_options(disable_filter)

    -- the project file is not found?
    if not os.isfile(project.rootfile()) then
        return {}, nil
    end

    -- reload the project file to ensure `if is_plat() then add_packagedirs() end` works
    local ok, errors = project._load(true, disable_filter)
    if not ok then
        return nil, errors
    end

    -- load the options from the the project file
    local results, errors = project._load_scope("option", true, not disable_filter)
    if not results then
        return nil, errors
    end

    -- load the options from the package directories, e.g. packagedir/*.pkg
    for _, packagedir in ipairs(table.wrap(project.get("packagedirs"))) do
        local packagefiles = os.files(path.join(packagedir, "*.pkg", "xmake.lua"))
        if packagefiles then
            for _, packagefile in ipairs(packagefiles) do

                -- load the package file
                local interp = option.interpreter()
                local ok, errors = interp:load(packagefile)
                if not ok then
                    return nil, errors
                end

                -- load the package options from the the package file
                local packageinfos, errors = interp:make("option", true, not disable_filter)
                if not packageinfos then
                    return nil, errors
                end

                -- transform includedirs and linkdirs
                local rootdir = path.directory(packagefile)
                for _, packageinfo in pairs(packageinfos) do
                    local linkdirs = {}
                    local includedirs = {}
                    for _, linkdir in ipairs(table.wrap(packageinfo:get("linkdirs"))) do
                        table.insert(linkdirs, path.is_absolute(linkdir) and linkdir or path.join(rootdir, linkdir))
                    end
                    for _, includedir in ipairs(table.wrap(packageinfo:get("includedirs"))) do
                        table.insert(includedirs, path.is_absolute(includedir) and includedir or path.join(rootdir, includedir))
                    end
                    if #linkdirs > 0 then
                        packageinfo:set("linkdirs", linkdirs)
                    end
                    if #includedirs > 0 then
                        packageinfo:set("includedirs", includedirs)
                    end
                end
                table.join2(results, packageinfos)
            end
        end
    end

    -- check options
    local options = {}
    for optionname, optioninfo in pairs(results) do

        -- init an option instance
        local instance = option.new(optionname, optioninfo)

        -- save it
        options[optionname] = instance

        -- mark add_defines_h_if_ok and add_undefines_h_if_ok as deprecated
        if instance:get("defines_h_if_ok") then
            deprecated.add("add_defines_h(\"%s\")", "add_defines_h_if_ok(\"%s\")", table.concat(table.wrap(instance:get("defines_h_if_ok")), "\", \""))
        end
        if instance:get("undefines_h_if_ok") then
            deprecated.add("add_undefines_h(\"%s\")", "add_undefines_h_if_ok(\"%s\")", table.concat(table.wrap(instance:get("undefines_h_if_ok")), "\", \""))
        end
    end

    -- load and attach options deps
    for _, opt in pairs(options) do
        opt._DEPS      = opt._DEPS or {}
        opt._ORDERDEPS = opt._ORDERDEPS or {}
        project._load_deps(opt, options, opt._DEPS, opt._ORDERDEPS)
    end

    -- ok?
    return options
end

-- load requires
function project._load_requires()

    -- parse requires
    local requires = {}
    local requires_str, requires_extra = project.requires_str()
    requires_extra = requires_extra or {}
    for _, requirestr in ipairs(table.wrap(requires_str)) do

        -- get the package name
        local packagename = requirestr:split('%s')[1]

        -- get alias
        local alias = nil
        local extrainfo = requires_extra[requirestr]
        if extrainfo then
            alias = extrainfo.alias
        end

        -- load it from cache first (@note will discard scripts in extrainfo)
        local instance = requireinfo.load(alias or packagename)
        if not instance then

            -- init a require info instance
            instance = table.inherit(requireinfo)

            -- save name and info
            instance._NAME = alias or packagename
            instance._INFO = { __requirestr = requirestr, __extrainfo = extrainfo }
        end

        -- move scripts of extrainfo  (e.g. on_load ..)
        if extrainfo then
            for k, v in pairs(extrainfo) do
                if type(v) == "function" then
                    instance._SCRIPTS = instance._SCRIPTS or {}
                    instance._SCRIPTS[k] = v
                    extrainfo[k] = nil
                end
            end

            -- TODO exists deprecated option? show tips
            if extrainfo.option then
                os.raise("`option = {}` is no longger supported in add_requires(), please update xmake.lua")
            end
        end

        -- add require info
        requires[alias or packagename] = instance
    end
    return requires
end

-- load the packages from the the project file and disable filter, we will process filter after a while
function project._load_packages()

    -- load the project file first if has not been loaded?
    local ok, errors = project._load()
    if not ok then
        return nil, errors
    end

    -- load packages
    return project._load_scope("package", true, false)
end

-- sort targets for all deps
function project._sort_targets(targets, ordertargets, targetrefs, target)
    for _, depname in ipairs(table.wrap(target:get("deps"))) do
        local targetinst = targets[depname]
        if targetinst then
            project._sort_targets(targets, ordertargets, targetrefs, targetinst)
        end
    end
    if not targetrefs[target:name()] then
        targetrefs[target:name()] = true
        table.insert(ordertargets, target)
    end
end

-- get project apis
function project.apis()

    return
    {
        values =
        {
            -- set_xxx
            "set_project"
        ,   "set_modes"     -- TODO deprecated
        ,   "set_description"
            -- add_xxx
        ,   "add_requires"
        ,   "add_repositories"
        }
    ,   paths =
        {
            -- add_xxx
            "add_packagedirs"
        }
    ,   keyvalues =
        {
            "set_config"
        }
    ,   custom =
        {
            -- is_xxx
            {"is_os",                   project._api_is_os            }
        ,   {"is_kind",                 project._api_is_kind          }
        ,   {"is_arch",                 project._api_is_arch          }
        ,   {"is_mode",                 project._api_is_mode          }
        ,   {"is_plat",                 project._api_is_plat          }
        ,   {"is_config",               project._api_is_config        }
            -- get_xxx
        ,   {"get_config",              project._api_get_config       }
            -- has_xxx
        ,   {"has_config",              project._api_has_config       }
        ,   {"has_package",             project._api_has_package      }
            -- add_xxx
        ,   {"add_moduledirs",          project._api_add_moduledirs   }
        ,   {"add_plugindirs",          project._api_add_plugindirs   }
        ,   {"add_platformdirs",        project._api_add_platformdirs }
        }
    }
end

-- get interpreter
function project.interpreter()

    -- the interpreter has been initialized? return it directly
    if project._INTERPRETER then
        return project._INTERPRETER
    end

    -- init interpreter
    local interp = interpreter.new()
    assert(interp)

    -- set root directory
    interp:rootdir_set(project.directory())

    -- set root scope
    interp:rootscope_set("target")

    -- define apis for rule
    interp:api_define(rule.apis())

    -- define apis for task
    interp:api_define(task.apis())

    -- define apis for target
    interp:api_define(target.apis())

    -- define apis for option
    interp:api_define(option.apis())

    -- define apis for package
    interp:api_define(package.apis())

    -- define apis for language
    interp:api_define(language.apis())

    -- define apis for toolchain
    interp:api_define(toolchain.apis())

    -- define apis for project
    interp:api_define(project.apis())

    -- register api: deprecated
    deprecated_project.api_register(interp)

    -- set filter
    interp:filter():register("project", function (variable)

        -- check
        assert(variable)

        -- hack buildir first
        if variable == "buildir" then
            return config.buildir()
        end

        -- attempt to get it directly from the configure
        local result = config.get(variable)
        if not result or type(result) ~= "string" then

            -- init maps
            local maps =
            {
                os          = platform.os()
            ,   host        = os.host()
            ,   subhost     = os.subhost()
            ,   prefix      = "$(prefix)"
            ,   tmpdir      = function () return os.tmpdir() end
            ,   curdir      = function () return os.curdir() end
            ,   scriptdir   = function () return sandbox_os.scriptdir() end
            ,   globaldir   = global.directory()
            ,   configdir   = config.directory()
            ,   projectdir  = project.directory()
            ,   programdir  = os.programdir()
            }

            -- map it
            result = maps[variable]
            if type(result) == "function" then
                result = result()
            end

            -- attempt to get it from the platform tools, e.g. cc, cxx, ld ..
            -- because these values may not exist in config cache when call `config.get()`, we need check and get it.
            --
            if not result then
                result = platform.tool(variable)
            end
        end

        -- ok?
        return result
    end)

    -- save interpreter
    project._INTERPRETER = interp

    -- ok?
    return interp
end

-- get the root project file
function project.rootfile()
    return os.projectfile()
end

-- get all loaded project files with subfiles (xmake.lua)
function project.allfiles()
    local rcfile = project.rcfile()
    if rcfile and os.isfile(rcfile) then
        return table.join(project.interpreter():scriptfiles(), rcfile)
    else
        return project.interpreter():scriptfiles()
    end
end

-- get the global rcfile: ~/.xmakerc.lua
function project.rcfile()
    local xmakerc = project._XMAKE_RCFILE
    if xmakerc == nil then
        xmakerc = "/etc/xmakerc.lua"
        if not os.isfile(xmakerc) then
            xmakerc = "~/.xmakerc.lua"
            if not os.isfile(xmakerc) then
                xmakerc = path.join(global.directory(), "xmakerc.lua")
            end
        end
        project._XMAKE_RCFILE = xmakerc
    end
    return xmakerc
end

-- get the project directory
function project.directory()
    return os.projectdir()
end

-- get the filelock of the whole project directory
function project.filelock()
    local errors
    local filelock = project._FILELOCK
    if filelock == nil then
        filelock, errors = io.openlock(path.join(config.directory(), "project.lock"))
        project._FILELOCK = filelock
    end
    return filelock, errors
end

-- get the project info from the given name
function project.get(name)
    return project._INFO and project._INFO:get(name) or nil
end

-- get the project name
function project.name()
    local name = project.get("project")
    -- TODO multi project names? we only get the first name now.
    -- and we need improve it in the future.
    if type(name) == "table" then
        name = name[1]
    end
    return name
end

-- get the project version, the root version of the target scope
function project.version()
    return project.get("target.version")
end

-- get the project policy, the root policy of the target scope
function project.policy(name)
    local policies = project._POLICIES
    if not policies then
        policies = project.get("target.policy")
        project._POLICIES = policies
        if policies then
            local defined_policies = policy.policies()
            for name, _ in pairs(policies) do
                if not defined_policies[name] then
                    utils.warning("unknown policy(%s), please run `xmake l core.project.policy.policies` if you want to all policies", name)
                end
            end
        end
    end
    return policy.check(name, policies and policies[name])
end

-- clear project cache to reload targets and options
function project.clear()

    -- clear options status in config file first
    for _, opt in ipairs(table.wrap(project._OPTIONS)) do
        opt:clear()
    end

    -- clear targets and options
    project._TARGETS = nil
    project._OPTIONS = nil
end

-- get the given target
function project.target(name)
    return project.targets()[name]
end

-- get targets
function project.targets()
    if not project._TARGETS then
        local targets, ordertargets, errors = project._load_targets()
        if not targets or not ordertargets then
            os.raise(errors)
        end
        project._TARGETS = targets
        project._ORDERTARGETS = ordertargets
    end
    return project._TARGETS
end

-- get order targets
function project.ordertargets()
    if not project._ORDERTARGETS then
        -- ensure _ORDERTARGETS to be initialized
        project.targets()
    end
    return project._ORDERTARGETS
end

-- get the given option
function project.option(name)
    return project.options()[name]
end

-- get options
function project.options()

    -- load options and enable filter
    if not project._OPTIONS then
        local options, errors = project._load_options()
        if not options then
            os.raise(errors)
        end
        project._OPTIONS = options
    end

    -- ok
    return project._OPTIONS
end

-- get the given require info
function project.require(name)
    return project.requires()[name]
end

-- get requires info
function project.requires()
    if not project._REQUIRES then
        local requires, errors = project._load_requires()
        if not requires then
            os.raise(errors)
        end
        project._REQUIRES = requires
    end
    return project._REQUIRES
end

-- get string requires
function project.requires_str()
    if not project._REQUIRES_STR then

        -- reload the project file to handle `has_config()`
        local ok, errors = project._load(true)
        if not ok then
            os.raise(errors)
        end

        -- get raw requires
        local requires_str, requires_extra = project.get("requires"), project.get("__extra_requires")
        project._REQUIRES_STR = requires_str or false
        project._REQUIRES_EXTRA = requires_extra
    end
    return project._REQUIRES_STR or nil, project._REQUIRES_EXTRA
end

-- get the given rule
function project.rule(name)
    return project.rules()[name]
end

-- get project rules
function project.rules()
    if not project._RULES then
        local rules, errors = project._load_rules()
        if not rules then
            os.raise(errors)
        end
        project._RULES = rules
    end
    return project._RULES
end

-- get the given toolchain
function project.toolchain(name)
    return project.toolchains()[name]
end

-- get project toolchains
function project.toolchains()
    if not project._TOOLCHAINS then
        local toolchains, errors = project._load_toolchains()
        if not toolchains then
            os.raise(errors)
        end
        project._TOOLCHAINS = toolchains
    end
    return project._TOOLCHAINS
end

-- get the given task
function project.task(name)
    return project.tasks()[name]
end

-- get tasks
function project.tasks()

    if not project._TASKS then

        -- load tasks
        local tasks, errors = project._load_tasks()
        if not tasks then
            os.raise(errors)
        end
        project._TASKS = tasks
    end
    return project._TASKS
end

-- get packages
function project.packages()

    if not project._PACKAGES then

        -- load packages
        local packages, errors = project._load_packages()
        if not packages then
            return nil, errors
        end
        project._PACKAGES = packages
    end
    return project._PACKAGES
end

-- get the mtimes
function project.mtimes()
    return project.interpreter():mtimes()
end

-- get the project modes
function project.modes()
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

-- get the project menu
function project.menu()

    -- attempt to load options from the project file
    local options = nil
    local errors = nil
    if os.isfile(project.rootfile()) then
        options, errors = project._load_options(true)
    end

    -- failed?
    if not options then
        if errors then utils.error(errors) end
        return {}
    end

    -- arrange options by category
    local options_by_category = {}
    for _, opt in pairs(options) do

        -- make the category
        local category = "default"
        if opt:get("category") then category = table.unwrap(opt:get("category")) end
        options_by_category[category] = options_by_category[category] or {}

        -- append option to the current category
        options_by_category[category][opt:name()] = opt
    end

    -- make menu by category
    local menu = {}
    for k, opts in pairs(options_by_category) do

        -- insert options
        local first = true
        for name, opt in pairs(opts) do

            -- show menu?
            if opt:get("showmenu") then

                -- the default value
                local default = "auto"
                if opt:get("default") ~= nil then
                    default = opt:get("default")
                end

                -- is first?
                if first then

                    -- insert a separator
                    table.insert(menu, {})

                    -- not first
                    first = false
                end

                -- append it
                local longname = name
                local descriptions = opt:get("description")
                if descriptions then

                    -- define menu option
                    local menu_options = {nil, longname, "kv", default, descriptions}

                    -- handle set_description("xx", "xx")
                    if type(descriptions) == "table" then
                        for i, description in ipairs(descriptions) do
                            menu_options[4 + i] = description
                        end
                    end

                    -- insert option into menu
                    table.insert(menu, menu_options)
                else
                    table.insert(menu, {nil, longname, "kv", default, nil})
                end
            end
        end
    end
    return menu
end

-- get the temporary directory of project
function project.tmpdir(opt)

    local tmpdir = project._TMPDIR
    if not tmpdir then
        if os.isdir(config.directory()) then
            local tmpdir_root = path.join(config.directory(), "tmp")
            tmpdir = path.join(tmpdir_root, os.date("%y%m%d"))
            if not os.isdir(tmpdir) then
                os.mkdir(tmpdir)
            end
        else
            tmpdir = os.tmpdir()
        end
    end
    return tmpdir
end

-- generate the temporary file path of project
--
-- e.g.
-- project.tmpfile("key")
-- project.tmpfile({key = "xxx"})
--
function project.tmpfile(opt_or_key)
    local opt
    local key = opt_or_key
    if type(key) == "table" then
        key = opt_or_key.key
        opt = opt_or_key
    end
    return path.join(project.tmpdir(opt), "_" .. (hash.uuid4(key):gsub("-", "")))
end

-- return module: project
return project
