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
local option                = require("base/option")
local filter                = require("base/filter")
local interpreter           = require("base/interpreter")
local target                = require("project/target")
local config                = require("project/config")
local deprecated_project    = require("project/deprecated/project")
local linker                = require("platform/linker")
local compiler              = require("platform/compiler")
local platform              = require("platform/platform")

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

    -- make option
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

        -- make option
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

    -- make option
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

        -- make option
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
    local interp = interpreter.init()
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
    interp:filter_set(filter.init(function (variable)

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

-- make option for checking links
function project._make_option_for_checking_links(opt, links, cfile, objectfile, targetfile)

    -- the links string
    local links_str = table.concat(table.wrap(links), ", ")
    
    -- this links has been checked?
    project._CHECKED_LINKS = project._CHECKED_LINKS or {}
    if project._CHECKED_LINKS[links_str] then return true end
    
    -- only for compile a object file
    local ok = compiler.check_include(opt, nil, cfile, objectfile)

    -- check link
    if ok then ok = linker.check_links(opt, links, cfile, objectfile, targetfile) end

    -- trace
    utils.printf("checking for the links %s ... %s", links_str, utils.ifelse(ok, "ok", "no"))

    -- cache the result
    project._CHECKED_LINKS[links_str] = ok

    -- ok?
    return ok
end

-- make option for checking cincludes
function project._make_option_for_checking_cincludes(opt, cincludes, cfile, objectfile)

    -- done
    for _, cinclude in ipairs(table.wrap(cincludes)) do
        
        -- this cinclude has been checked?
        project._CHECKED_CINCLUDES = project._CHECKED_CINCLUDES or {}
        if project._CHECKED_CINCLUDES[cinclude] then return true end
        
        -- check cinclude
        local ok = compiler.check_include(opt, cinclude, cfile, objectfile)

        -- trace
        utils.printf("checking for the c include %s ... %s", cinclude, utils.ifelse(ok, "ok", "no"))

        -- cache the result
        project._CHECKED_CINCLUDES[cinclude] = ok

        -- failed
        if not ok then return false end
    end

    -- ok
    return true
end

-- make option for checking cxxincludes
function project._make_option_for_checking_cxxincludes(opt, cxxincludes, cxxfile, objectfile)

    -- done
    for _, cxxinclude in ipairs(table.wrap(cxxincludes)) do
         
        -- this cxxinclude has been checked?
        project._CHECKED_CXXINCLUDES = project._CHECKED_CXXINCLUDES or {}
        if project._CHECKED_CXXINCLUDES[cinclude] then return true end
        
        -- check cinclude
        local ok = compiler.check_include(opt, cxxinclude, cxxfile, objectfile)

        -- trace
        utils.printf("checking for the c++ include %s ... %s", cxxinclude, utils.ifelse(ok, "ok", "no"))

        -- cache the result
        project._CHECKED_CXXINCLUDES[cxxinclude] = ok

        -- failed
        if not ok then return false end
    end

    -- ok
    return true
end

-- make option for checking cfunctions
function project._make_option_for_checking_cfuncs(opt, cfuncs, cfile, objectfile, targetfile)

    -- done
    for _, cfunc in ipairs(table.wrap(cfuncs)) do
        
        -- check function
        local ok = compiler.check_function(opt, cfunc, cfile, objectfile)

        -- check link
        if ok and opt.links then ok = linker.check_links(opt, opt.links, cfile, objectfile, targetfile) end

        -- trace
        utils.printf("checking for the c function %s ... %s", cfunc, utils.ifelse(ok, "ok", "no"))

        -- failed
        if not ok then return false end
    end

    -- ok
    return true
end

-- make option for checking cxxfunctions
function project._make_option_for_checking_cxxfuncs(opt, cxxfuncs, cxxfile, objectfile, targetfile)

    -- done
    for _, cxxfunc in ipairs(table.wrap(cxxfuncs)) do
        
        -- check function
        local ok = compiler.check_function(opt, cxxfunc, cxxfile, objectfile)

        -- check link
        if ok and opt.links then ok = linker.check_links(opt, opt.links, cxxfile, objectfile, targetfile) end

        -- trace
        utils.printf("checking for the c++ function %s ... %s", cxxfunc, utils.ifelse(ok, "ok", "no"))

        -- failed
        if not ok then return false end
    end

    -- ok
    return true
end

-- make option for checking ctypes
function project._make_option_for_checking_ctypes(opt, ctypes, cfile, objectfile, targetfile)

    -- done
    for _, ctype in ipairs(table.wrap(ctypes)) do
        
        -- check type
        local ok = compiler.check_typedef(opt, ctype, cfile, objectfile)

        -- trace
        utils.printf("checking for the c type %s ... %s", ctype, utils.ifelse(ok, "ok", "no"))

        -- failed
        if not ok then return false end
    end

    -- ok
    return true
end

-- make option for checking cxxtypes
function project._make_option_for_checking_cxxtypes(opt, cxxtypes, cxxfile, objectfile, targetfile)

    -- done
    for _, cxxtype in ipairs(table.wrap(cxxtypes)) do
        
        -- check type
        local ok = compiler.check_typedef(opt, cxxtype, cxxfile, objectfile)

        -- trace
        utils.printf("checking for the c++ type %s ... %s", cxxtype, utils.ifelse(ok, "ok", "no"))

        -- failed
        if not ok then return false end
    end

    -- ok
    return true
end

-- make option 
function project._make_option(name, opt, cfile, cxxfile, objectfile, targetfile)

    -- check links
    if opt.links and not project._make_option_for_checking_links(opt, opt.links, cfile, objectfile, targetfile) then return end

    -- check ctypes
    if opt.ctypes and not project._make_option_for_checking_ctypes(opt, opt.ctypes, cfile, objectfile, targetfile) then return end

    -- check cxxtypes
    if opt.cxxtypes and not project._make_option_for_checking_cxxtypes(opt, opt.cxxtypes, cxxfile, objectfile, targetfile) then return end

    -- check includes and functions
    if opt.cincludes or opt.cxxincludes then

        -- check cincludes
        if opt.cincludes and not project._make_option_for_checking_cincludes(opt, opt.cincludes, cfile, objectfile) then return end

        -- check cxxincludes
        if opt.cxxincludes and not project._make_option_for_checking_cxxincludes(opt, opt.cxxincludes, cxxfile, objectfile) then return end

        -- check cfuncs
        if opt.cfuncs and not project._make_option_for_checking_cfuncs(opt, opt.cfuncs, cfile, objectfile, targetfile) then return end

        -- check cxxfuncs
        if opt.cxxfuncs and not project._make_option_for_checking_cxxfuncs(opt, opt.cxxfuncs, cxxfile, objectfile, targetfile) then return end

    end

    -- ok
    return opt
end

-- make options from the project file
function project._make_options(options)

    -- check
    assert(options)
  
    -- the source file path
    local cfile     = os.tmpdir() .. "/__checking.c"
    local cxxfile   = os.tmpdir() .. "/__checking.cpp"

    -- the object file path
    local objectfile = os.tmpdir() .. "/" .. target.filename("__checking", "object")

    -- the target file path
    local targetfile = os.tmpdir() .. "/" .. target.filename("__checking", "binary")

    -- make all options
    for k, v in pairs(options) do

        -- this option need be probed automatically?
        if config.get(name) == nil then

            -- make option
            local o = project._make_option(k, v, cfile, cxxfile, objectfile, targetfile)
            if o then

                -- enable this option
                config.set(k, true)

                -- save this option to configure 
                config.set("__" .. k, o)

            else

                -- disable this option
                config.set(k, false)

                -- clear this option to configure 
                config.set("__" .. k, nil)

            end

        elseif nil == config.get("__" .. k) then

            -- save this option to configure 
            config.set("__" .. k, v)
        end
    end

    -- remove files
    os.rm(cfile)
    os.rm(cxxfile)
    os.rm(objectfile)
    os.rm(targetfile)

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

-- probe the project 
function project.probe()

    -- get interpreter
    local interp = project._interpreter()
    assert(interp) 

    -- enter the project directory
    local ok, errors = os.cd(xmake._PROJECT_DIR)
    if not ok then
        return false, errors
    end

    -- load the options from the the project file
    local options, errors = interp:load(xmake._PROJECT_FILE, "option", true, true)
    if not options then
        return false, errors
    end

    -- make the options from the the project file
    project._make_options(options)

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

    -- load targets
    local targets, errors = interp:load(xmake._PROJECT_FILE, "target", true, true)
    if not targets then
        return false, errors
    end

    -- leave the project directory
    ok, errors = os.cd("-")
    if not ok then
        return false, errors
    end

    -- save targets
    project._TARGETS = targets

    -- ok
    return true
end

-- dump the current configure
function project.dump()
    
    -- dump
    if option.get("verbose") then
        table.dump(project.targets())
    end
   
end

-- get the project menu
function project.menu()

    -- get interpreter
    local interp = project._interpreter()
    assert(interp) 

    -- attempt to load options from the project file
    local options = nil
    local errors = nil
    local projectfile = xmake._PROJECT_FILE
    if projectfile and os.isfile(projectfile) then
        options, errors = interp:load(projectfile, "option", true, false)
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
        if opt.category then category = table.unwrap(opt.category) end
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
            if opt.showmenu then

                -- the default value
                local default = "auto"
                if opt.enable ~= nil then
                    default = opt.enable
                end

                -- is first?
                if first then

                    -- insert a separator
                    table.insert(menu, {})

                    -- not first
                    first = false
                end

                -- append it
                if opt.description then
                    table.insert(menu, {nil, name, "kv", default, opt.description})
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
