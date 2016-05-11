--!The Automatic Cross-platform Build Tool
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
local interpreter           = require("base/interpreter")
local target                = require("project/target")
local config                = require("project/config")
local option                = require("project/option")
local deprecated_project    = require("project/deprecated/project")
local platform              = require("platform/platform")
local environment           = require("platform/environment")

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
function project._api_add_cfunc(interp, module, alias, links, includes, cfunc)

    -- check
    assert(interp and cfunc)

    -- make the option name
    local name = nil
    if module ~= nil then
        name = string.format("__%s_%s", module, cfunc)
    else
        name = string.format("__%s", cfunc)
    end

    -- make the option define
    local define = nil
    if module ~= nil then
        define = string.format("$(prefix)_%s_HAVE_%s", module:upper(), utils.ifelse(alias, alias, cfunc:upper()))
    else
        define = string.format("$(prefix)_HAVE_%s", utils.ifelse(alias, alias, cfunc:upper()))
    end

    -- save the current scope
    local scope = interp:scope_save()

    -- check option
    interp:api_call("option", name)
    interp:api_call("set_option_category", "cfuncs")
    interp:api_call("add_option_cfuncs", cfunc)
    if links then interp:api_call("add_option_links", links) end
    if includes then interp:api_call("add_option_cincludes", includes) end
    interp:api_call("add_option_defines_h_if_ok", define)

    -- restore the current scope
    interp:scope_restore(scope)

    -- add this option to the current scope
    interp:api_call("add_options", name)
end

-- add c functions
function project._api_add_cfuncs(interp, module, links, includes, ...)

    -- check
    assert(interp)

    -- done
    for _, cfunc in ipairs({...}) do

        -- check
        assert(cfunc)

        -- make the option name
        local name = nil
        if module ~= nil then
            name = string.format("__%s_%s", module, cfunc)
        else
            name = string.format("__%s", cfunc)
        end

        -- make the option define
        local define = nil
        if module ~= nil then
            define = string.format("$(prefix)_%s_HAVE_%s", module:upper(), cfunc:upper())
        else
            define = string.format("$(prefix)_HAVE_%s", cfunc:upper())
        end

        -- save the current scope
        local scope = interp:scope_save()

        -- check option
        interp:api_call("option", name)
        interp:api_call("set_option_category", "cfuncs")
        interp:api_call("add_option_cfuncs", cfunc)
        if links then interp:api_call("add_option_links", links) end
        if includes then interp:api_call("add_option_cincludes", includes) end
        interp:api_call("add_option_defines_h_if_ok", define)

        -- restore the current scope
        interp:scope_restore(scope)

        -- add this option 
        interp:api_call("add_options", name)
    end
end

-- add c++ function
function project._api_add_cxxfunc(interp, module, alias, links, includes, cxxfunc)

    -- check
    assert(interp and cxxfunc)

    -- make the option name
    local name = nil
    if module ~= nil then
        name = string.format("__%s_%s", module, cxxfunc)
    else
        name = string.format("__%s", cxxfunc)
    end

    -- make the option define
    local define = nil
    if module ~= nil then
        define = string.format("$(prefix)_%s_HAVE_%s", module:upper(), utils.ifelse(alias, alias, cxxfunc:upper()))
    else
        define = string.format("$(prefix)_HAVE_%s", utils.ifelse(alias, alias, cxxfunc:upper()))
    end

    -- save the current scope
    local scope = interp:scope_save()

    -- check option
    interp:api_call("option", name)
    interp:api_call("set_option_category", "cxxfuncs")
    interp:api_call("add_option_cxxfuncs", cxxfunc)
    if links then interp:api_call("add_option_links", links) end
    if includes then interp:api_call("add_option_cxxincludes", includes) end
    interp:api_call("add_option_defines_h_if_ok", define)

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
    for _, cxxfunc in ipairs({...}) do

        -- check
        assert(cxxfunc)

        -- make the option name
        local name = nil
        if module ~= nil then
            name = string.format("__%s_%s", module, cxxfunc)
        else
            name = string.format("__%s", cxxfunc)
        end

        -- make the option define
        local define = nil
        if module ~= nil then
            define = string.format("$(prefix)_%s_HAVE_%s", module:upper(), cxxfunc:upper())
        else
            define = string.format("$(prefix)_HAVE_%s", cxxfunc:upper())
        end

        -- save the current scope
        local scope = interp:scope_save()

        -- check option
        interp:api_call("option", name)
        interp:api_call("set_option_category", "cxxfuncs")
        interp:api_call("add_option_cxxfuncs", cxxfunc)
        if links then interp:api_call("add_option_links", links) end
        if includes then interp:api_call("add_option_cxxincludes", includes) end
        interp:api_call("add_option_defines_h_if_ok", define)

        -- restore the current scope
        interp:scope_restore(scope)

        -- add this option 
        interp:api_call("add_options", name)
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
    interp:rootdir_set(xmake._PROJECT_DIR)

    -- register api: deprecated
    deprecated_project.api_register(interp)
    
    -- register api: target() and option()
    interp:api_register_scope("target", "option")

    -- register api: on_run() and on_install() and on_package()
    interp:api_register_on_script("target", nil,            "run"
                                                        ,   "install"
                                                        ,   "package")

    -- register api: set_values() for target
    interp:api_register_set_values("target", nil,           "kind"
                                                        ,   "config_h_prefix"
                                                        ,   "version"
                                                        ,   "strip"
                                                        ,   "options"
                                                        ,   "symbols"
                                                        ,   "warnings"
                                                        ,   "optimize"
                                                        ,   "languages")

    -- register api: add_values() for target
    interp:api_register_add_values("target", nil,           "deps"
                                                        ,   "links"
                                                        ,   "cflags" 
                                                        ,   "cxflags" 
                                                        ,   "cxxflags" 
                                                        ,   "mflags" 
                                                        ,   "mxflags" 
                                                        ,   "mxxflags" 
                                                        ,   "ldflags" 
                                                        ,   "shflags" 
                                                        ,   "options"
                                                        ,   "defines"
                                                        ,   "undefines"
                                                        ,   "defines_h"
                                                        ,   "undefines_h"
                                                        ,   "languages"
                                                        ,   "vectorexts")

    -- register api: set_pathes() for target
    interp:api_register_set_pathes("target", nil,           "headerdir" 
                                                        ,   "targetdir" 
                                                        ,   "objectdir" 
                                                        ,   "config_h")

    -- register api: add_pathes() for target
    interp:api_register_add_pathes("target", nil,           "files"
                                                        ,   "headers" 
                                                        ,   "linkdirs" 
                                                        ,   "includedirs")

 
    -- register api: on_action() for target
    interp.api_register_on_script(interp, "target", nil,    "run"
                                                        ,   "build"
                                                        ,   "clean"
                                                        ,   "package"
                                                        ,   "install"
                                                        ,   "uninstall")

    -- register api: before_action() for target
    interp.api_register_before_script(interp, "target", nil,    "run"
                                                            ,   "build"
                                                            ,   "clean"
                                                            ,   "package"
                                                            ,   "install"
                                                            ,   "uninstall")

    -- register api: after_action() for target
    interp.api_register_after_script(interp, "target", nil, "run"
                                                        ,   "build"
                                                        ,   "clean"
                                                        ,   "package"
                                                        ,   "install"
                                                        ,   "uninstall")

    -- register api: set_option_values() for option
    interp:api_register_set_values("option", "option",      "enable"
                                                        ,   "showmenu"
                                                        ,   "category"
                                                        ,   "warnings"
                                                        ,   "optimize"
                                                        ,   "languages"
                                                        ,   "description")
    
    -- register api: add_option_values() for option
    interp:api_register_add_values("option", "option",      "links" 
                                                        ,   "cincludes" 
                                                        ,   "cxxincludes" 
                                                        ,   "cfuncs" 
                                                        ,   "cxxfuncs" 
                                                        ,   "ctypes" 
                                                        ,   "cxxtypes" 
                                                        ,   "cflags" 
                                                        ,   "cxflags" 
                                                        ,   "cxxflags" 
                                                        ,   "ldflags" 
                                                        ,   "vectorexts"
                                                        ,   "defines"
                                                        ,   "defines_if_ok"
                                                        ,   "defines_h_if_ok"
                                                        ,   "undefines"
                                                        ,   "undefines_if_ok"
                                                        ,   "undefines_h_if_ok")

    -- register api: add_option_pathes() for option
    interp:api_register_add_pathes("option", "option",      "linkdirs" 
                                                        ,   "includedirs")

    -- register api: is_os(), is_kind(), is_mode(), is_plat(), is_arch(), is_option()
    interp:api_register("is_os", project._api_is_os)
    interp:api_register("is_kind", project._api_is_kind)
    interp:api_register("is_mode", project._api_is_mode)
    interp:api_register("is_plat", project._api_is_plat)
    interp:api_register("is_arch", project._api_is_arch)
    interp:api_register("is_option", project._api_is_option)

    -- register api: add_cfunc()
    interp:api_register("add_cfunc", project._api_add_cfunc)

    -- register api: add_cfuncs()
    interp:api_register("add_cfuncs", project._api_add_cfuncs)

    -- register api: add_cxxfunc()
    interp:api_register("add_cxxfunc", project._api_add_cxxfunc)

    -- register api: add_cxxfuncs()
    interp:api_register("add_cxxfuncs", project._api_add_cxxfuncs)

    -- register api: add_pkgdirs()
    interp:api_register("add_pkgdirs", project._api_add_pkgdirs)

    -- register api: add_pkgs()
    interp:api_register("add_pkgs", interpreter.api_builtin_add_subdirs)

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
            ,   projectdir  = xmake._PROJECT_DIR
            }

            -- map it
            result = maps[variable]

        end

        -- ok?
        return result
    end))

    -- save interpreter
    project._INTERPRETER = interp

    -- ok?
    return interp
end

-- check the project 
function project.check()

    -- enter the project directory
    local ok, errors = os.cd(xmake._PROJECT_DIR)
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
 
    -- the source file path
    local cfile     = path.join(os.tmpdir(), "__checking.c")
    local cxxfile   = path.join(os.tmpdir(), "__checking.cpp")

    -- the object file path
    local objectfile = path.join(os.tmpdir(), target.filename("__checking", "object"))

    -- the target file path
    local targetfile = path.join(os.tmpdir(), target.filename("__checking", "binary"))

    -- make all options
    for name, opt in pairs(options) do

        -- need check?
        if config.get(name) == nil then

            -- check option
            if opt:check(cfile, cxxfile, objectfile, targetfile) then

                -- enable this option
                config.set(name, true)

                -- save this option to configure 
                opt:save()

            else

                -- disable this option
                config.set(name, false)

                -- clear this option to configure 
                opt:clear()

            end
        end
    end

    -- remove files
    os.rm(cfile)
    os.rm(cxxfile)
    os.rm(objectfile)
    os.rm(targetfile)

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
    local ok, errors = os.cd(xmake._PROJECT_DIR)
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
                if opt:get("enable") ~= nil then
                    default = opt:get("enable")
                end

                -- is first?
                if first then

                    -- insert a separator
                    table.insert(menu, {})

                    -- not first
                    first = false
                end

                -- append it
                if opt:get("description") then
                    table.insert(menu, {nil, name, "kv", default, opt:get("description")})
                else
                    table.insert(menu, {nil, name, "kv", default, nil})
                end
            end
        end
    end

    -- ok?
    return menu
end

-- return module: project
return project
