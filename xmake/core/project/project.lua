--!The Make-like Build Utility based on Lua
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
-- Copyright (C) 2015 - 2017, TBOOX Open Source Group.
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
local utils                 = require("base/utils")
local table                 = require("base/table")
local process               = require("base/process")
local deprecated            = require("base/deprecated")
local interpreter           = require("base/interpreter")
local target                = require("project/target")
local config                = require("project/config")
local global                = require("base/global")
local option                = require("project/option")
local package               = require("project/package")
local deprecated_project    = require("project/deprecated/project")
local platform              = require("platform/platform")
local environment           = require("platform/environment")
local language              = require("language/language")
local sandbox_os            = require("sandbox/modules/os")
local sandbox_module        = require("sandbox/modules/import/core/sandbox/module")

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

    -- get the current mode
    local mode = config.get("mode")
    if not mode then return false end

    -- exists this mode?
    for _, m in ipairs(table.join(...)) do
        if m and type(m) == "string" and m == mode then
            return true
        end
    end
end

-- the current platform is belong to the given platforms?
function project._api_is_plat(interp, ...)

    -- get the current platform
    local plat = config.get("plat")
    if not plat then return false end

    -- exists this platform? and escape '-'
    for _, p in ipairs(table.join(...)) do
        if p and type(p) == "string" and plat:find(p:gsub("%-", "%%-")) then
            return true
        end
    end
end

-- the current platform is belong to the given architectures?
function project._api_is_arch(interp, ...)

    -- get the current architecture
    local arch = config.get("arch")
    if not arch then return false end

    -- exists this architecture? and escape '-'
    for _, a in ipairs(table.join(...)) do
        if a and type(a) == "string" and arch:find(a:gsub("%-", "%%-")) then
            return true
        end
    end
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

-- the current host is belong to the given hosts?
function project._api_is_host(interp, ...)

    -- get the current host
    local host = xmake._HOST
    if not host then return false end

    -- exists this host? and escape '-'
    for _, h in ipairs(table.join(...)) do
        if h and type(h) == "string" and host:find(h:gsub("%-", "%%-")) then
            return true
        end
    end
end

-- enable options?
function project._api_is_option(interp, ...)

    -- some options are enabled?
    for _, o in ipairs(table.join(...)) do
        if o and type(o) == "string" and config.get(o) then
            return true
        end
    end
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

-- add package directories and load all packages from the given directories
function project._api_add_packagedirs(interp, ...)

    -- get all directories
    local pkgdirs = {}
    local dirs = table.join(...)
    for _, dir in ipairs(dirs) do
        table.insert(pkgdirs, dir .. "/*.pkg")
    end

    -- add all packages
    interp:api_builtin_includes(pkgdirs)
end

-- get interpreter
function project._interpreter()

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

    -- define apis for language
    interp:api_define(language.apis())

    -- define apis for target, option and task
    interp:api_define
    {
        values =
        {
            -- set_xxx
            "set_project"
        ,   "set_version"
        ,   "set_modes"
            -- target.set_xxx
        ,   "target.set_kind"
        ,   "target.set_strip"
        ,   "target.set_default"
        ,   "target.set_options"
        ,   "target.set_symbols"
        ,   "target.set_basename"
        ,   "target.set_warnings"
        ,   "target.set_optimize"
        ,   "target.set_languages"
            -- target.add_xxx
        ,   "target.add_deps"
        ,   "target.add_options"
        ,   "target.add_languages"
        ,   "target.add_vectorexts"
            -- option.set_xxx
        ,   "option.set_default"
        ,   "option.set_showmenu"
        ,   "option.set_category"
        ,   "option.set_warnings"
        ,   "option.set_optimize"
        ,   "option.set_languages"
        ,   "option.set_description"
            -- option.add_xxx
        ,   "option.add_deps"
        ,   "option.add_vectorexts"
        ,   "option.add_bindings"  -- deprecated
        ,   "option.add_rbindings" -- deprecated
            -- task.set_xxx
        ,   "task.set_category"
        ,   "task.set_menu"
        }
    ,   pathes = 
        {
            -- target.set_xxx
            "target.set_targetdir"
        ,   "target.set_objectdir"
            -- target.add_xxx
        ,   "target.add_files"
        }
    ,   script =
        {
            -- target.on_xxx
            "target.on_run"
        ,   "target.on_load"
        ,   "target.on_build"
        ,   "target.on_clean"
        ,   "target.on_package"
        ,   "target.on_install"
        ,   "target.on_uninstall"
            -- target.before_xxx
        ,   "target.before_run"
        ,   "target.before_build"
        ,   "target.before_clean"
        ,   "target.before_package"
        ,   "target.before_install"
        ,   "target.before_uninstall"
            -- target.after_xxx
        ,   "target.after_run"
        ,   "target.after_build"
        ,   "target.after_clean"
        ,   "target.after_package"
        ,   "target.after_install"
        ,   "target.after_uninstall"
            -- option.before_xxx
        ,   "option.before_check"
            -- option.on_xxx
        ,   "option.on_check"
            -- option.after_xxx
        ,   "option.after_check"
            -- target.on_xxx
        ,   "task.on_run"
        }
    ,   custom = 
        {
            -- is_xxx
            {"is_os",                   project._api_is_os            }
        ,   {"is_kind",                 project._api_is_kind          }
        ,   {"is_host",                 project._api_is_host          }
        ,   {"is_mode",                 project._api_is_mode          }
        ,   {"is_plat",                 project._api_is_plat          }
        ,   {"is_arch",                 project._api_is_arch          }
        ,   {"is_option",               project._api_is_option        }
            -- add_xxx
        ,   {"add_moduledirs",          project._api_add_moduledirs   }
        ,   {"add_plugindirs",          project._api_add_plugindirs   }
        ,   {"add_packagedirs",         project._api_add_packagedirs  }
        }
    }

    -- register api: add_packages() to target
    interp:api_register_builtin("add_packages", interp:_api_within_scope("target", "add_options"))

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
            ,   prefix      = "$(prefix)"
            ,   tmpdir      = function () return os.tmpdir() end
            ,   curdir      = function () return os.curdir() end
            ,   scriptdir   = function () return sandbox_os.scriptdir() end
            ,   globaldir   = global.directory()
            ,   configdir   = config.directory()
            ,   projectdir  = project.directory()
            ,   packagedir  = package.directory()
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
    project._INTERPRETER = interp

    -- ok?
    return interp
end

-- load targets 
function project._load_targets()

    -- get interpreter
    local interp = project._interpreter()
    assert(interp) 

    -- enter the project directory
    local oldir, errors = os.cd(os.projectdir())
    if not oldir then
        return nil, errors
    end

    -- load targets
    local results, errors = interp:load(project.file(), "target", true, true)
    if not results then
        return nil, errors
    end

    -- leave the project directory
    local ok, errors = os.cd(oldir)
    if not ok then
        return nil, errors
    end

    -- make targets
    local targets = {}
    for targetname, targetinfo in pairs(results) do
        targets[targetname] = target.new(targetname, targetinfo)
    end

    -- load and attach target deps
    for _, target in pairs(targets) do
        target._DEPS = {}
        for _, dep in ipairs(table.wrap(target:get("deps"))) do
            target._DEPS[dep] = targets[dep]
        end
    end

    -- enter toolchains environment
    environment.enter("toolchains")

    -- on load for each target
    for _, target in pairs(targets) do
        local on_load = target:script("load")
        if on_load then
            ok, errors = sandbox.load(on_load, target)
            if not ok then
                break
            end
        end
    end

    -- leave toolchains environment
    environment.leave("toolchains")

    -- on load failed?
    if not ok then
        return nil, errors
    end

    -- ok
    return targets
end

-- load options
function project._load_options(disable_filter)

    -- get interpreter
    local interp = project._interpreter()
    assert(interp) 

    -- enter the project directory
    local oldir, errors = os.cd(os.projectdir())
    if not oldir then
        return nil, errors
    end

    -- load the options from the the project file
    local results, errors = interp:load(project.file(), "option", true, not disable_filter)
    if not results then
        return nil, errors
    end

    -- leave the project directory
    local ok, errors = os.cd(oldir)
    if not ok then
        return nil, errors
    end

    -- check options
    local options = {}
    for optionname, optioninfo in pairs(results) do
        
        -- init a option instance
        local instance = table.inherit(option)
        assert(instance)

        -- save name and info
        instance._NAME = optionname
        instance._INFO = optioninfo

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
        opt._DEPS = {}
        for _, dep in ipairs(table.wrap(opt:get("deps"))) do
            opt._DEPS[dep] = options[dep]
        end
    end

    -- ok?
    return options
end

-- get the project file
function project.file()
    return os.projectfile()
end

-- get the project directory
function project.directory()
    return os.projectdir()
end

-- get the project info from the given name
function project.get(name)

    -- load the global project infos
    local infos = project._INFOS 
    if not infos then

        -- get interpreter
        local interp = project._interpreter()
        assert(interp) 

        -- load infos
        infos = interp:load(project.file(), nil, true, true)
        project._INFOS = infos
    end

    -- get it
    if infos then
        return infos[name]
    end
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

-- get the current configure for targets
function project.targets()

    -- load targets
    if not project._TARGETS then
        local targets, errors = project._load_targets()
        if not targets then
            os.raise(errors)
        end
        project._TARGETS = targets
    end

    -- ok
    return project._TARGETS
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

-- get tasks
function project.tasks()

    -- get interpreter
    local interp = project._interpreter()
    assert(interp) 

    -- the project file is not found?
    if not os.isfile(project.file()) then
        return {}, nil
    end

    -- load the tasks from the the project file
    local results, errors = interp:load(project.file(), "task", true, true)
    if not results then
        return nil, errors
    end

    -- ok?
    return results, interp
end

-- get the mtimes
function project.mtimes()

    -- get interpreter
    local interp = project._interpreter()
    assert(interp) 

    -- get it
    return interp:mtimes()
end

-- get the project menu
function project.menu()

    -- attempt to load options from the project file
    local options = nil
    local errors = nil
    if os.isfile(project.file()) then
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

                -- deprecated, make bindings
                local bindings = nil
                if opt:get("bindings") then
                    bindings = string.join(table.wrap(opt:get("bindings")), ',')
                end
                if opt:get("rbindings") then
                    bindings = "!" .. string.join(table.wrap(opt:get("rbindings")), ",!")
                end

                -- make longname
                local longname = name
                if bindings ~= nil then
                    longname = longname .. ":" .. bindings
                end

                -- append it
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

    -- ok?
    return menu
end

-- return module: project
return project
