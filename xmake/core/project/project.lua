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
local hashset               = require("base/hashset")
local baseoption            = require("base/option")
local deprecated            = require("base/deprecated")
local interpreter           = require("base/interpreter")
local instance_deps         = require("base/private/instance_deps")
local memcache              = require("cache/memcache")
local rule                  = require("project/rule")
local target                = require("project/target")
local config                = require("project/config")
local option                = require("project/option")
local policy                = require("project/policy")
local project_package       = require("project/package")
local deprecated_project    = require("project/deprecated/project")
local package               = require("package/package")
local platform              = require("platform/platform")
local toolchain             = require("tool/toolchain")
local language              = require("language/language")
local sandbox_os            = require("sandbox/modules/os")
local sandbox_module        = require("sandbox/modules/import/core/sandbox/module")

-- register project to platform, rule and target
platform._PROJECT = project
target._PROJECT = project
rule._PROJECT = project

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
    local requires = project._memcache():get("requires")
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
    if project._memcache():get("rootinfo") and not force then
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
            for _, xmakerc_file in ipairs(project.rcfiles()) do
                if xmakerc_file and os.isfile(xmakerc_file) then
                    local rcdata = io.readfile(xmakerc_file)
                    if rcdata then
                        data = rcdata .. "\n" .. data
                    end
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
    project._memcache():set("rootinfo", rootinfo)
    project._memcache():set("rootinfo_target", rootinfo_target)

    -- leave the project directory
    oldir, errors = os.cd(oldir)
    if not oldir then
        return false, errors
    end
    return true
end

-- load scope from the project file
function project._load_scope(scope_kind, deduplicate, enable_filter)

    -- enter the project directory
    local oldir, errors = os.cd(os.projectdir())
    if not oldir then
        return nil, errors
    end

    -- get interpreter
    local interp = project.interpreter()

    -- load scope
    local results, errors = interp:make(scope_kind, deduplicate, enable_filter)
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
        toolchains[toolchain_name] = toolchain_info
    end
    return toolchains
end

-- load targets
function project._load_targets()

    -- mark targets have been loaded even if it may fail to load.
    -- because once loaded, there will be some cached state, such as options,
    -- so if we load it a second time, there will be some hidden state inconsistencies.
    project._memcache():set("targets_loaded", true)

    -- load all requires first and reload the project file to ensure has_package() works for targets
    local requires = project.required_packages()
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
        local t = target.new(targetname, targetinfo)
        if t and (t:get("enabled") == nil or t:get("enabled") == true) then
            targets[targetname] = t
        end
    end

    -- load and attach target deps, rules and packages
    for _, t in pairs(targets) do

        -- load rules from target and language
        t._RULES = t._RULES or {}
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
                -- only add target rules
                if r:kind() == "target" then
                    t._RULES[rulename] = r
                    for _, deprule in ipairs(r:orderdeps()) do
                        t._RULES[deprule:name()] = deprule
                    end
                end
            -- we need ignore `@package/rulename`, it will be loaded later
            elseif not rulename:match("@.-/") then
                return nil, string.format("unknown rule(%s) in target(%s)!", rulename, t:name())
            end
        end

        -- @note it's deprecated, please use on_load instead of before_load
        ok, errors = t:_load_before()
        if not ok then
            return nil, errors
        end

        -- we need call on_load() before building deps/rules,
        -- so we can use `target:add("deps", "xxx")` to add deps in on_load
        ok, errors = t:_load()
        if not ok then
            return nil, errors
        end
    end
    return targets
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
        local instance = option.new(optionname, optioninfo)
        options[optionname] = instance
    end

    -- load and attach options deps
    for _, opt in pairs(options) do
        opt._DEPS      = opt._DEPS or {}
        opt._ORDERDEPS = opt._ORDERDEPS or {}
        instance_deps.load_deps(opt, options, opt._DEPS, opt._ORDERDEPS, {opt:name()})
    end
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
        local packagename = requirestr:split("%s")[1]

        -- get alias and requireconfs
        local alias = nil
        local requireconfs = requires_extra[requirestr]
        if requireconfs then
            alias = requireconfs.alias
        end

        -- load it from cache first
        local name = alias or packagename
        local instance = project_package.load(name)
        if not instance then
            local info = {__requirestr = requirestr, __requireconfs = requireconfs}
            instance = project_package.load_withinfo(name, info)
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

-- get project memcache
function project._memcache()
    return memcache.cache("core.project.project")
end

-- get project toolchain infos (@note only with toolchain info)
function project._toolchains()
    local toolchains = project._memcache():get("toolchains")
    if not toolchains then
        local errors
        toolchains, errors = project._load_toolchains()
        if not toolchains then
            os.raise(errors)
        end
        -- load toolchains from data file from "package.tools.xmake" module
        local toolchain_datafiles = os.getenv("XMAKE_TOOLCHAIN_DATAFILES")
        if toolchain_datafiles then
            toolchain_datafiles = path.splitenv(toolchain_datafiles)
            if toolchain_datafiles and #toolchain_datafiles > 0 then
                for _, toolchain_datafile in ipairs(toolchain_datafiles) do
                    local toolchain_inst, errors = toolchain.load_fromfile(toolchain_datafile)
                    if toolchain_inst then
                        -- @note we use this passed toolchain configuration first if this toolchain has been defined in current project
                        toolchains[toolchain_inst:name()] = toolchain_inst
                    else
                        os.raise(errors)
                    end
                end
            end
        end
        project._memcache():set("toolchains", toolchains)
    end
    return toolchains
end

-- get project apis
function project.apis()

    return
    {
        values =
        {
            -- set_xxx
            "set_project"
        ,   "set_description"
        ,   "set_allowedmodes"
        ,   "set_allowedplats"
        ,   "set_allowedarchs"
        ,   "set_defaultmode"
        ,   "set_defaultplat"
        ,   "set_defaultarchs"
            -- add_xxx
        ,   "add_requires"
        ,   "add_requireconfs"
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

    -- we need to be able to precisely control the direction of deduplication of different types of values.
    -- the default is to de-duplicate from left to right, but like links/syslinks need to be de-duplicated from right to left.
    --
    -- @see https://github.com/xmake-io/xmake/issues/1903
    --
    interp:deduplication_policy_set("links", "toleft")
    interp:deduplication_policy_set("syslinks", "toleft")
    interp:deduplication_policy_set("frameworks", "toleft")

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
            ,   tmpdir      = function () return os.tmpdir() end
            ,   curdir      = function () return os.curdir() end
            ,   scriptdir   = function () return interp:pending() and interp:scriptdir() or sandbox_os.scriptdir() end
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
    local files = {}
    table.join2(files, project.interpreter():scriptfiles())
    for _, rcfile in ipairs(project.rcfiles()) do
        if rcfile and os.isfile(rcfile) then
            table.insert(files, rcfile)
        end
    end
    return files
end

-- get the global rcfiles: ~/.xmakerc.lua
function project.rcfiles()
    local rcfiles = project._XMAKE_RCFILES
    if rcfiles == nil then
        rcfiles = {}
        local rcpaths = {}
        local rcpaths_env = os.getenv("XMAKE_RCFILES")
        if rcpaths_env then
            table.join2(rcpaths, path.splitenv(rcpaths_env))
        end
        table.join2(rcpaths, {"/etc/xmakerc.lua", "~/.xmakerc.lua", path.join(global.directory(), "xmakerc.lua")})
        for _, rcfile in ipairs(rcpaths) do
            if os.isfile(rcfile) then
                table.insert(rcfiles, rcfile)
            end
        end
        project._XMAKE_RCFILES = rcfiles
    end
    return rcfiles
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

-- get the root configuration
function project.get(name)
    local rootinfo
    if name and name:startswith("target.") then
        name = name:sub(8)
        rootinfo = project._memcache():get("rootinfo_target")
    else
        rootinfo = project._memcache():get("rootinfo")
    end
    return rootinfo and rootinfo:get(name) or nil
end

-- get the root extra configuration
function project.extraconf(name, item, key)
    local rootinfo
    if name and name:startswith("target.") then
        name = name:sub(8)
        rootinfo = project._memcache():get("rootinfo_target")
    else
        rootinfo = project._memcache():get("rootinfo")
    end
    return rootinfo and rootinfo:extraconf(name, item, key) or nil
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
    local policies = project._memcache():get("policies")
    if not policies then
        -- get policies from project, e.g. set_policy("xxx", true)
        policies = project.get("target.policy")
        -- get policies from config, e.g. xmake f --policies=package.precompiled:n,package.install_only
        -- @see https://github.com/xmake-io/xmake/issues/2318
        local policies_config = config.get("policies")
        if policies_config then
            for _, policy in ipairs(policies_config:split(",", {plain = true})) do
                local splitinfo = policy:split(":", {limit = 2})
                if #splitinfo > 1 then
                    policies = policies or {}
                    policies[splitinfo[1]] = baseoption.boolean(splitinfo[2])
                else
                    policies = policies or {}
                    policies[splitinfo[1]] = true
                end
            end
        end
        project._memcache():set("policies", policies)
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

-- project has been loaded?
function project.is_loaded()
    return project._memcache():get("targets_loaded")
end

-- get the given target
function project.target(name)
    local targets = project.targets()
    return targets and targets[name]
end

-- add the given target, @note if the target name is the same, it will be replaced
function project.target_add(t)
    local targets = project.targets()
    if targets then
        targets[t:name()] = t
        project._memcache():set("ordertargets", nil)
    end
end

-- get targets
function project.targets()
    local loading = false
    local targets = project._memcache():get("targets")
    if not targets then
        local errors
        targets, errors = project._load_targets()
        if errors then
            os.raise(errors)
        end
        project._memcache():set("targets", targets)
        loading = true
    end
    if loading then
        -- do after_load() for targets
        -- @note we must call it after finishing to cache targets
        -- because we maybe will call project.targets() in after_load, we need avoid dead recursion loop
        for _, t in ipairs(project.ordertargets()) do
            local ok, errors = t:_load_after()
            if not ok then
                os.raise(errors or string.format("load target %s failed", t:name()))
            end
        end
    end
    return targets
end

-- get order targets
function project.ordertargets()
    local ordertargets = project._memcache():get("ordertargets")
    if not ordertargets then
        local targets = project.targets()
        ordertargets = {}
        local targetrefs = {}
        for _, t in table.orderpairs(targets) do
            instance_deps.sort_deps(targets, ordertargets, targetrefs, t)
        end
        project._memcache():set("ordertargets", ordertargets)
    end
    return ordertargets
end

-- get the given option
function project.option(name)
    return project.options()[name]
end

-- get options
function project.options()
    local options = project._memcache():get("options")
    if not options then
        local errors
        options, errors = project._load_options()
        if not options then
            os.raise(errors)
        end
        project._memcache():set("options", options)
    end
    return options
end

-- get the given required package
function project.required_package(name)
    return project.required_packages()[name]
end

-- get required packages
function project.required_packages()
    local requires = project._memcache():get("requires")
    if not requires then
        local errors
        requires, errors = project._load_requires()
        if not requires then
            os.raise(errors)
        end
        project._memcache():set("requires", requires)
    end
    return requires
end

-- get string requires
function project.requires_str()
    local requires_str   = project._memcache():get("requires_str")
    local requires_extra = project._memcache():get("requires_extra")
    if not requires_str then

        -- reload the project file to handle `has_config()`
        local ok, errors = project._load(true)
        if not ok then
            os.raise(errors)
        end

        -- get raw requires
        requires_str, requires_extra = project.get("requires"), project.get("__extra_requires")
        project._memcache():set("requires_str", requires_str or false)
        project._memcache():set("requires_extra", requires_extra)

        -- get raw requireconfs
        local requireconfs_str, requireconfs_extra = project.get("requireconfs"), project.get("__extra_requireconfs")
        project._memcache():set("requireconfs_str", requireconfs_str or false)
        project._memcache():set("requireconfs_extra", requireconfs_extra)
    end
    return requires_str or nil, requires_extra
end

-- get string requireconfs
function project.requireconfs_str()
    project.requires_str()
    local requireconfs_str   = project._memcache():get("requireconfs_str")
    local requireconfs_extra = project._memcache():get("requireconfs_extra")
    return requireconfs_str, requireconfs_extra
end

-- get requires lockfile
function project.requireslock()
    return path.join(project.directory(), "xmake-requires.lock")
end

-- get the format version of requires lockfile
function project.requireslock_version()
    return "1.0"
end

-- get the given rule
function project.rule(name)
    return project.rules()[name]
end

-- get project rules
function project.rules()
    local rules = project._memcache():get("rules")
    if not rules then
        local errors
        rules, errors = project._load_rules()
        if not rules then
            os.raise(errors)
        end
        project._memcache():set("rules", rules)
    end
    return rules
end

-- get the given toolchain
function project.toolchain(name, opt)
    local toolchain_name = toolchain.parsename(name) -- we need ignore `@packagename`
    local info = project._toolchains()[toolchain_name]
    if info then
        return toolchain.load_withinfo(name, info, opt)
    end
end

-- get project toolchains list
function project.toolchains()
    return table.keys(project._toolchains())
end

-- get the given task
function project.task(name)
    return project.tasks()[name]
end

-- get tasks
function project.tasks()
    local tasks = project._memcache():get("tasks")
    if not tasks then
        local errors
        tasks, errors = project._load_tasks()
        if not tasks then
            os.raise(errors)
        end
        project._memcache():set("tasks", tasks)
    end
    return tasks
end

-- get packages
function project.packages()
    local packages = project._memcache():get("packages")
    if not packages then
        local errors
        packages, errors = project._load_packages()
        if not packages then
            return nil, errors
        end
        project._memcache():set("packages", packages)
    end
    return packages
end

-- get the mtimes
function project.mtimes()
    local mtimes = project._MTIMES
    if not mtimes then
        mtimes = project.interpreter():mtimes()
        for _, rcfile in ipairs(project.rcfiles()) do
            mtimes[rcfile] = os.mtime(rcfile)
        end
        project._MTIMES = mtimes
    end
    return mtimes
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
            if opt:showmenu() ~= false then

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
                local description = opt:description()
                if description then

                    -- define menu option
                    local menu_options = {nil, longname, "kv", default, description}

                    -- handle set_description("xx", "xx")
                    if type(description) == "table" then
                        for i, description in ipairs(description) do
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

-- get all modes
function project.modes()
    local modes
    local allowed_modes = project.allowed_modes()
    if allowed_modes then
        modes = allowed_modes:to_array()
    else
        modes = {}
        for _, target in table.orderpairs(table.wrap(project.targets())) do
            for _, rule in ipairs(target:orderules()) do
                local name = rule:name()
                if name:startswith("mode.") then
                    table.insert(modes, name:sub(6))
                end
            end
        end
        modes = table.unique(modes)
    end
    return modes
end

-- get default architectures from the given platform
--
-- set_defaultarchs("linux|x86_64", "iphoneos|arm64")
--
function project.default_arch(plat)
    local default_archs = project._memcache():get("defaultarchs")
    if not default_archs then
        default_archs = {}
        for _, defaultarch in ipairs(table.wrap(project.get("defaultarchs"))) do
            local splitinfo = defaultarch:split('|')
            if #splitinfo == 2 then
                default_archs[splitinfo[1]] = splitinfo[2]
            elseif #splitinfo == 1 and not default_archs.default then
                default_archs.default = defaultarch
            end
        end
        project._memcache():set("defaultarchs", default_archs or false)
    end
    return default_archs[plat or "default"] or default_archs["default"]
end

-- get allowed modes
--
-- set_allowedmodes("releasedbg", "debug")
--
function project.allowed_modes()
    local allowed_modes_set = project._memcache():get("allowedmodes")
    if not allowed_modes_set then
        local allowed_modes = table.wrap(project.get("allowedmodes"))
        if #allowed_modes > 0 then
            allowed_modes_set = hashset.from(allowed_modes)
        end
        project._memcache():set("allowedmodes", allowed_modes_set or false)
    end
    return allowed_modes_set or nil
end

-- get allowed platforms
--
-- set_allowedplats("windows", "mingw", "linux", "macosx")
--
function project.allowed_plats()
    local allowed_plats_set = project._memcache():get("allowedplats")
    if not allowed_plats_set then
        local allowed_plats = table.wrap(project.get("allowedplats"))
        if #allowed_plats > 0 then
            allowed_plats_set = hashset.from(allowed_plats)
        end
        project._memcache():set("allowedplats", allowed_plats_set or false)
    end
    return allowed_plats_set or nil
end

-- get allowed architectures
--
-- set_allowedarchs("macosx|arm64", "macosx|x86_64", "linux|i386")
--
function project.allowed_archs(plat)
    plat = plat or ""
    local allowed_archs_set = project._memcache():get2("allowedarchs", plat)
    if not allowed_archs_set then
        local allowed_archs = table.wrap(project.get("allowedarchs"))
        if #allowed_archs > 0 then
            for _, allowed_arch in ipairs(allowed_archs) do
                local splitinfo = allowed_arch:split('|')
                local splitplat, splitarch
                if #splitinfo == 2 then
                    splitplat = splitinfo[1]
                    splitarch = splitinfo[2]
                elseif #splitinfo == 1 then
                    splitarch = allowed_arch
                end
                if plat == splitplat or splitplat == nil then
                    if not allowed_archs_set then
                        allowed_archs_set = hashset.new()
                    end
                    allowed_archs_set:insert(splitarch)
                end
            end
        end
        project._memcache():set2("allowedarchs", plat, allowed_archs_set or false)
    end
    return allowed_archs_set or nil
end

-- return module: project
return project
