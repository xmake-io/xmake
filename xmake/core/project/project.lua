--!The Make-like Build Utility based on Lua
-- 
-- XMake is free software; you can redistribute it and/or modify
-- it under the terms of the GNU Lesser General Public License as published by
-- the Free Software Foundation; either version 2.1 of the License, or
-- (at your option) any later version.
-- 
-- XMake is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU Lesser General Public License for more details.
-- 
-- You should have received a copy of the GNU Lesser General Public License
-- along with XMake; 
-- If not, see <a href="http://www.gnu.org/licenses/"> http://www.gnu.org/licenses/</a>
-- 
-- Copyright (C) 2015 - 2016, ruki All rights reserved.
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
local filter                = require("base/filter")
local deprecated            = require("base/deprecated")
local interpreter           = require("base/interpreter")
local target                = require("project/target")
local config                = require("project/config")
local global                = require("project/global")
local option                = require("project/option")
local package               = require("project/package")
local deprecated_project    = require("project/deprecated/project")
local platform              = require("platform/platform")
local environment           = require("platform/environment")
local language              = require("language/language")

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

-- enable options?
function project._api_is_option(interp, ...)

    -- some options are enabled?
    for _, o in ipairs(table.join(...)) do
        if o and type(o) == "string" and config.get(o) then
            return true
        end
    end
end

-- add c function
function project._api_add_cfunc(interp, module, alias, links, includes, checkinfo)

    -- check
    assert(interp)

    -- parse the check code
    local checkname, checkcode = option.checkinfo(checkinfo)
    assert(checkname and checkcode)

    -- make the option name
    local name = nil
    if module ~= nil then
        name = string.format("__%s_%s", module, checkname)
    else
        name = string.format("__%s", checkname)
    end

    -- uses the alias name
    if alias ~= nil then
        checkname = alias
    end

    -- make the option define
    local define = nil
    if module ~= nil then
        define = string.format("$(prefix)_%s_HAVE_%s", module:upper(), checkname:upper())
    else
        define = string.format("$(prefix)_HAVE_%s", checkname:upper())
    end

    -- save the current scope
    local scope = interp:scope_save()

    -- check option
    interp:api_call("option", name)
    interp:api_call("set_category", "cfuncs")
    interp:api_call("add_cfuncs", checkinfo)
    if links then interp:api_call("add_links", links) end
    if includes then interp:api_call("add_cincludes", includes) end
    interp:api_call("add_defines_h_if_ok", define)

    -- restore the current scope
    interp:scope_restore(scope)

    -- add this option 
    interp:api_call("add_options", name)
end

-- add c functions
function project._api_add_cfuncs(interp, module, links, includes, ...)

    -- check
    assert(interp)

    -- done
    for _, checkinfo in ipairs({...}) do
        project._api_add_cfunc(interp, module, nil, links, includes, checkinfo)
    end
end

-- add c++ function
function project._api_add_cxxfunc(interp, module, alias, links, includes, checkinfo)

    -- check
    assert(interp and module)

    -- parse the check code
    local checkname, checkcode = option.checkinfo(checkinfo)
    assert(checkname and checkcode)

    -- make the option name
    local name = nil
    if module ~= nil then
        name = string.format("__%s_%s", module, checkname)
    else
        name = string.format("__%s", checkname)
    end

    -- uses the alias name
    if alias ~= nil then
        checkname = alias
    end

    -- make the option define
    local define = nil
    if module ~= nil then
        define = string.format("$(prefix)_%s_HAVE_%s", module:upper(), checkname:upper())
    else
        define = string.format("$(prefix)_HAVE_%s", checkname:upper())
    end

    -- save the current scope
    local scope = interp:scope_save()

    -- check option
    interp:api_call("option", name)
    interp:api_call("set_category", "cxxfuncs")
    interp:api_call("add_cxxfuncs", checkinfo)
    if links then interp:api_call("add_links", links) end
    if includes then interp:api_call("add_cxxincludes", includes) end
    interp:api_call("add_defines_h_if_ok", define)

    -- restore the current scope
    interp:scope_restore(scope)

    -- add this option 
    interp:api_call("add_options", name)
end

-- add c++ functions
function project._api_add_cxxfuncs(interp, module, links, includes, ...)

    -- check
    assert(interp and module)

    -- done
    for _, checkinfo in ipairs({...}) do
        project._api_add_cxxfunc(interp, module, nil, links, includes, checkinfo)
    end
end

-- load all packages from the given directories
function project._api_add_pkgdirs(interp, ...)

    -- get all directories
    local pkgdirs = {}
    local dirs = table.join(...)
    for _, dir in ipairs(dirs) do
        table.insert(pkgdirs, dir .. "/*.pkg")
    end

    -- add all packages
    interp:api_builtin_add_subdirs(pkgdirs)
end

-- load all plugins from the given directories
function project._api_add_plugindirs(interp, ...)

    -- get all directories
    local plugindirs = {}
    local dirs = table.join(...)
    for _, dir in ipairs(dirs) do
        table.insert(plugindirs, dir .. "/*")
    end

    -- add all plugins
    interp:api_builtin_add_subdirs(plugindirs)
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

    -- register api: target(), option() and task()
    interp:api_register_scope("target", "option", "task")

    -- define apis for language
    interp:api_define(language.apis())

    -- register api: set_values() to target
    interp:api_register_set_values("target",    "kind"
                                            ,   "version"
                                            ,   "project"
                                            ,   "strip"
                                            ,   "options"
                                            ,   "symbols"
                                            ,   "warnings"
                                            ,   "optimize"
                                            ,   "languages")

    -- register api: add_values() to target
    interp:api_register_add_values("target",    "deps"
                                            ,   "options"
                                            ,   "languages"
                                            ,   "vectorexts")

    -- register api: set_pathes() to target
    interp:api_register_set_pathes("target",    "targetdir" 
                                            ,   "objectdir")

    -- register api: add_pathes() to target
    interp:api_register_add_pathes("target",    "files")

 
    -- register api: on_action() to target
    interp:api_register_on_script("target",     "run"
                                            ,   "build"
                                            ,   "clean"
                                            ,   "package"
                                            ,   "install"
                                            ,   "uninstall")

    -- register api: before_action() to target
    interp:api_register_before_script("target", "run"
                                            ,   "build"
                                            ,   "clean"
                                            ,   "package"
                                            ,   "install"
                                            ,   "uninstall")

    -- register api: after_action() to target
    interp:api_register_after_script("target",  "run"
                                            ,   "build"
                                            ,   "clean"
                                            ,   "package"
                                            ,   "install"
                                            ,   "uninstall")

    -- register api: set_values() to option
    interp:api_register_set_values("option",    "default"
                                            ,   "showmenu"
                                            ,   "category"
                                            ,   "warnings"
                                            ,   "optimize"
                                            ,   "languages"
                                            ,   "description")
    
    -- register api: add_values() to option
    interp:api_register_add_values("option",    "vectorexts"
                                            ,   "bindings"
                                            ,   "rbindings")

    -- register api: add_cfunc() and add_cfuncs() to target
    interp:api_register("target", "add_cfunc", project._api_add_cfunc)
    interp:api_register("target", "add_cfuncs", project._api_add_cfuncs)

    -- register api: add_cxxfunc() and add_cxxfuncs() to target
    interp:api_register("target", "add_cxxfunc", project._api_add_cxxfunc)
    interp:api_register("target", "add_cxxfuncs", project._api_add_cxxfuncs)

    -- register api: add_packages() to target
    interp:api_register_builtin("add_packages", interp:_api_within_scope("target", "add_options"))

    -- register api: set_category()
    --
    -- category: main, action, plugin, task (default)
    interp:api_register_set_values("task", "category")

    -- register api: set_menu() 
    interp:api_register_set_values("task", "menu")

    -- register api: on_run()
    interp:api_register_on_script("task", "run")

    -- register api: is_xxx() to root
    interp:api_register(nil, "is_os",       project._api_is_os)
    interp:api_register(nil, "is_kind",     project._api_is_kind)
    interp:api_register(nil, "is_mode",     project._api_is_mode)
    interp:api_register(nil, "is_plat",     project._api_is_plat)
    interp:api_register(nil, "is_arch",     project._api_is_arch)
    interp:api_register(nil, "is_option",   project._api_is_option)

    -- register api: add_packagedirs() to root
    interp:api_register(nil, "add_packagedirs", project._api_add_pkgdirs)

    -- register api: add_plugindirs() to root
    interp:api_register(nil, "add_plugindirs", project._api_add_plugindirs)

    -- register api: deprecated
    deprecated_project.api_register(interp)

    -- set filter
    interp:filter_set(filter.new(function (variable)

        -- check
        assert(variable)

        -- attempt to get it directly from the configure
        local result = config.get(variable)
        if not result or type(result) ~= "string" then 

            -- init maps
            local maps = 
            {
                os          = platform.os()
            ,   host        = xmake._HOST
            ,   prefix      = "$(prefix)"
            ,   tmpdir      = os.tmpdir()
            ,   curdir      = os.curdir()
            ,   globaldir   = global.directory()
            ,   configdir   = config.directory()
            ,   projectdir  = project.directory()
            ,   packagedir  = package.directory()
            }

            -- map it
            result = maps[variable]

            -- deprecated for "$(OS)"
            if result == nil and variable == "OS" then

                -- get os:upper()
                result = platform.os():upper()

                -- deprecated
                deprecated.add("$(\"OS\")", "$(\"os:upper\")")
            end
        end

        -- ok?
        return result
    end))

    -- save interpreter
    project._INTERPRETER = interp

    -- ok?
    return interp
end

-- get the project directory
function project.directory()

    -- get it
    return xmake._PROJECT_DIR
end

-- check the project 
function project.check()

    -- enter the project directory
    local ok, errors = os.cd(project.directory())
    if not ok then
        return false, errors
    end

    -- load the options from the the project file
    local options, errors = project.options(true)
    if not options then
        return false, errors
    end

    -- enter toolchains environment
    environment.enter("toolchains")

    -- check all options
    for _, opt in pairs(options) do
        opt:check() 
    end

    -- leave toolchains environment
    environment.leave("toolchains")
 
    -- leave the project directory
    ok, errors = os.cd("-")
    if not ok then
        return false, errors
    end

    -- ok
    return true
end

-- load the project 
function project.load()

    -- get interpreter
    local interp = project._interpreter()
    assert(interp) 

    -- enter the project directory
    local ok, errors = os.cd(project.directory())
    if not ok then
        return false, errors
    end

    -- load results
    local results, errors = interp:load(xmake._PROJECT_FILE, "target", true, true)
    if not results then
        return false, errors
    end

    -- leave the project directory
    ok, errors = os.cd("-")
    if not ok then
        return false, errors
    end

    -- make targets
    local targets = {}
    for targetname, targetinfo in pairs(results) do
        
        -- init a target instance
        local instance = table.inherit(target)
        assert(instance)

        -- save name and info
        instance._NAME = targetname
        instance._INFO = targetinfo

        -- save it
        targets[targetname] = instance
    end

    -- save targets
    project._TARGETS = targets

    -- ok
    return true
end

-- get the given target
function project.target(targetname)

    -- check
    assert(targetname and targetname ~= "all")

    -- the targets
    local targets = project.targets()
    assert(targets)

    -- get it
    return targets[targetname]
end

-- get the current configure for targets
function project.targets()

    -- check
    assert(project._TARGETS)

    -- return it
    return project._TARGETS
end

-- get options
function project.options(enable_filter)

    -- get interpreter
    local interp = project._interpreter()
    assert(interp) 

    -- load the options from the the project file
    local results, errors = interp:load(xmake._PROJECT_FILE, "option", true, enable_filter)
    if not results then
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
    end

    -- ok?
    return options
end

-- get tasks
function project.tasks()

    -- get interpreter
    local interp = project._interpreter()
    assert(interp) 

    -- the project file is not found?
    if not os.isfile(xmake._PROJECT_FILE) then
        return {}, nil
    end

    -- load the tasks from the the project file
    local results, errors = interp:load(xmake._PROJECT_FILE, "task", true, true)
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
    if os.isfile(xmake._PROJECT_FILE) then
        options, errors = project.options(false)
    end

    -- failed?
    if not options then
        if errors then utils.error(errors) end
        return {}
    end

    -- arrange options by category
    local options_by_category = {}
    for name, opt in pairs(options) do

        -- make the category
        local category = "default"
        if opt:get("category") then category = table.unwrap(opt:get("category")) end
        options_by_category[category] = options_by_category[category] or {}

        -- append option to the current category
        options_by_category[category][name] = opt
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

                -- make bindings
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
