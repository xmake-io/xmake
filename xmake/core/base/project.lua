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
-- Copyright (C) 2009 - 2015, ruki All rights reserved.
--
-- @author      ruki
-- @file        project.lua
--

-- define module: project
local project = project or {}

-- load modules
local os            = require("base/os")
local io            = require("base/io")
local rule          = require("base/rule")
local path          = require("base/path")
local utils         = require("base/utils")
local table         = require("base/table")
local config        = require("base/config")
local filter        = require("base/filter")
local linker        = require("base/linker")
local compiler      = require("base/compiler")
local platform      = require("base/platform")
local interpreter   = require("base/interpreter")

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

-- TODO: deprecated
-- the current os is belong to the given os?
function project._api_os(interp, ...)

    -- make values
    local values = ""
    for _, v in ipairs(table.join(...)) do
        if v and type(v) == "string" then
            if #values == 0 then
                values = v
            else
                values = values .. ", " .. v
            end
        end
    end

    -- warning
    utils.warning("please uses is_os(\"%s\"), \"os()\" has been deprecated!", values)

    -- done
    return project._api_is_os(interp, ...)
end

-- TODO: deprecated
-- the current mode is belong to the given modes?
function project._api_modes(interp, ...)

    -- make values
    local values = ""
    for _, v in ipairs(table.join(...)) do
        if v and type(v) == "string" then
            if #values == 0 then
                values = v
            else
                values = values .. ", " .. v
            end
        end
    end

    -- warning
    utils.warning("please uses is_mode(\"%s\"), \"modes()\" has been deprecated!", values)

    -- done
    return project._api_is_mode(interp, ...)
end

-- TODO: deprecated
-- the current platform is belong to the given platforms?
function project._api_plats(interp, ...)

    -- make values
    local values = ""
    for _, v in ipairs(table.join(...)) do
        if v and type(v) == "string" then
            if #values == 0 then
                values = v
            else
                values = values .. ", " .. v
            end
        end
    end

    -- warning
    utils.warning("please uses is_plat(\"%s\"), \"plats()\" has been deprecated!", values)

    -- done
    return project._api_is_plat(interp, ...)
end

-- TODO: deprecated
-- the current platform is belong to the given architectures?
function project._api_archs(interp, ...)

    -- make values
    local values = ""
    for _, v in ipairs(table.join(...)) do
        if v and type(v) == "string" then
            if #values == 0 then
                values = v
            else
                values = values .. ", " .. v
            end
        end
    end

    -- warning
    utils.warning("please uses is_arch(\"%s\"), \"archs()\" has been deprecated!", values)

    -- done
    return project._api_is_arch(interp, ...)
end

-- TODO: deprecated
-- the current kind is belong to the given kinds?
function project._api_kinds(interp, ...)

    -- make values
    local values = ""
    for _, v in ipairs(table.join(...)) do
        if v and type(v) == "string" then
            if #values == 0 then
                values = v
            else
                values = values .. ", " .. v
            end
        end
    end

    -- warning
    utils.warning("please uses is_kind(\"%s\"), \"kinds()\" has been deprecated!", values)

    -- done
    return project._api_is_kind(interp, ...)
end

-- TODO: deprecated
-- enable options?
function project._api_options(interp, ...)

    -- make values
    local values = ""
    for _, v in ipairs(table.join(...)) do
        if v and type(v) == "string" then
            if #values == 0 then
                values = v
            else
                values = values .. ", " .. v
            end
        end
    end

    -- warning
    utils.warning("please uses is_option(\"%s\"), \"options()\" has been deprecated!", values)

    -- done
    return project._api_is_option(interp, ...)
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

    -- TODO: deprecated
    -- register api: set_target() and set_option()
    interp:api_register_set_scope("target", "option")
    interp:api_register_add_scope("target", "option")
    
    -- register api: target() and option()
    interp:api_register_scope("target", "option")

    -- register api: set_script() for target
    interp:api_register_set_script("target", nil,           "runscript"
                                                        ,   "installscript"
                                                        ,   "packagescript")

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


    -- TODO: deprecated
    -- register api: os(), kinds(), modes(), plats(), archs(), options()
    interp:api_register("os", project._api_os)
    interp:api_register("kinds", project._api_kinds)
    interp:api_register("modes", project._api_modes)
    interp:api_register("plats", project._api_plats)
    interp:api_register("archs", project._api_archs)
    interp:api_register("options", project._api_options)

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

-- make configure for the given target_name
function project._makeconf_for_target(target_name, target)

    -- check
    assert(target_name and target)

    -- get the target configure file 
    local config_h = target.config_h
    if not config_h then 
        return true
    end

    -- translate file path
    if not path.is_absolute(config_h) then
        config_h = path.absolute(config_h, xmake._PROJECT_DIR)
    else
        config_h = path.translate(config_h)
    end

    -- the prefix
    local prefix = target.config_h_prefix or (target_name:upper() .. "_CONFIG")

    -- open the file
    local file = project._CONFILES[config_h] or io.openmk(config_h)
    assert(file)

    -- make the head
    if project._CONFILES[config_h] then file:write("\n") end
    file:write(string.format("#ifndef %s_H\n", prefix))
    file:write(string.format("#define %s_H\n", prefix))
    file:write("\n")

    -- make version
    if target.version then
        file:write("// version\n")
        file:write(string.format("#define %s_VERSION \"%s\"\n", prefix, target.version))
        local i = 1
        local m = {"MAJOR", "MINOR", "ALTER"}
        for v in target.version:gmatch("%d+") do
            file:write(string.format("#define %s_VERSION_%s %s\n", prefix, m[i], v))
            i = i + 1
            if i > 3 then break end
        end
        file:write(string.format("#define %s_VERSION_BUILD %s\n", prefix, os.date("%Y%m%d%H%M", os.time())))
        file:write("\n")
    end

    -- make the defines
    local defines = {}
    if target.defines_h then table.join2(defines, target.defines_h) end

    -- make the undefines
    local undefines = {}
    if target.undefines_h then table.join2(undefines, target.undefines_h) end

    -- the options
    if target.options then
        for _, name in ipairs(utils.wrap(target.options)) do

            -- get option if be enabled
            local opt = nil
            if config.get(name) then opt = config.get("__" .. name) end
            if nil ~= opt then

                -- get the option defines
                if opt.defines_h_if_ok then table.join2(defines, opt.defines_h_if_ok) end

                -- get the option undefines
                if opt.undefines_h_if_ok then table.join2(undefines, opt.undefines_h_if_ok) end

            end
        end
    end

    -- make the defines
    if #defines ~= 0 then
        file:write("// defines\n")
        for _, define in ipairs(defines) do
            file:write(string.format("#define %s 1\n", define:gsub("=", " "):gsub("%$%((.-)%)", function (w) if w == "prefix" then return prefix end end)))
        end
        file:write("\n")
    end

    -- make the undefines 
    if #undefines ~= 0 then
        file:write("// undefines\n")
        for _, undefine in ipairs(undefines) do
            file:write(string.format("#undef %s\n", undefine:gsub("%$%((.-)%)", function (w) if w == "prefix" then return prefix end end)))
        end
        file:write("\n")
    end

    -- make the tail
    file:write("#endif\n")

    -- cache the file
    project._CONFILES[config_h] = file

    -- ok
    return true
end

-- make the configure file for the given target and dependents
function project._makeconf_for_target_and_deps(target_name)

    -- the targets
    local targets = project.targets()
    assert(targets)

    -- the target
    local target = targets[target_name]
    assert(target)

    -- make configure for the target
    if not project._makeconf_for_target(target_name, target) then
        return false 
    end
     
    -- exists the dependent targets?
    if target.deps then
        local deps = utils.wrap(target.deps)
        for _, dep in ipairs(deps) do
            if not project._makeconf_for_target_and_deps(dep) then return false end
        end
    end

    -- ok
    return true
end

-- make option for checking links
function project._make_option_for_checking_links(opt, links, cfile, objectfile, targetfile)

    -- the links string
    local links_str = table.concat(utils.wrap(links), ", ")
    
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
    for _, cinclude in ipairs(utils.wrap(cincludes)) do
        
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
    for _, cxxinclude in ipairs(utils.wrap(cxxincludes)) do
         
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
    for _, cfunc in ipairs(utils.wrap(cfuncs)) do
        
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
    for _, cxxfunc in ipairs(utils.wrap(cxxfuncs)) do
        
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
    for _, ctype in ipairs(utils.wrap(ctypes)) do
        
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
    for _, cxxtype in ipairs(utils.wrap(cxxtypes)) do
        
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
    local objectfile = os.tmpdir() .. "/" .. rule.filename("__checking", "object")

    -- the target file path
    local targetfile = os.tmpdir() .. "/" .. rule.filename("__checking", "binary")

    -- make all options
    for k, v in pairs(options) do

        -- this option need be probed automatically?
        if config.auto(k) then

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

    -- load the options from the the project file
    local options, errors = interp:load(xmake._PROJECT_FILE, "option", true, true)
    if not options then
        return errors
    end

    -- make the options from the the project file
    project._make_options(options)
end

-- load the project 
function project.load()

    -- get interpreter
    local interp = project._interpreter()
    assert(interp) 

    -- load targets
    local targets, errors = interp:load(xmake._PROJECT_FILE, "target", true, true)
    if not targets then
        return errors
    end

    -- save targets
    project._TARGETS = targets

    -- the mtimes for interpreter
    local mtimes = interp:mtimes()
    assert(mtimes)

    -- get the mtimes for configure
    local mtimes_config = config.get("__mtimes")
    if mtimes_config then 

        -- check for all project files and we need reconfig and rebuild it if them have been modified
        for file, mtime in pairs(mtimes) do

            -- modified? reconfig and rebuild it
            local mtime_old = mtimes_config[file]
            if not mtime_old or mtime > mtime_old then
                config._RECONFIG = true
                config.set("__rebuild", true)
                break
            end
        end
    end

    -- update mtimes
    config.set("__mtimes", mtimes)

    -- reconfig it? we need reprobe it
    if config._RECONFIG then
        project.probe()
        config.clearup()
    end
end

-- reload the project
function project.reload()

    -- load it
    return project.load()
end

-- dump the current configure
function project.dump()
    
    -- dump
    if xmake._OPTIONS.verbose then
        utils.dump(project.targets())
    end
   
end

-- make the configure file for the given target
function project.makeconf(target_name)

    -- init files
    project._CONFILES = {}

    -- the target name
    if target_name and target_name ~= "all" then
        -- make configure for the target and dependents
        if not project._makeconf_for_target_and_deps(target_name) then return false end
    else

        -- the targets
        local targets = project.targets()
        assert(targets)

        -- make configure for the targets
        for target_name, target in pairs(targets) do
            if not project._makeconf_for_target(target_name, target) then return false end
        end
    end

    -- exit files
    for _, file in pairs(project._CONFILES) do
        file:close()
    end
 
    -- ok
    return true
end

-- check target
function project.checktarget(target_name)

    -- the targets
    local targets = project.targets()

    -- invalid target?
    if target_name and target_name ~= "all" and targets and not targets[target_name] then
        utils.error("invalid target: %s!", target_name)
        return false
    elseif not target_name then
        utils.error("no target!")
        return false
    end

    -- ok
    return true
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
        if opt.category then category = utils.unwrap(opt.category) end
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
