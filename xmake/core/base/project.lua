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
local linker        = require("base/linker")
local compiler      = require("base/compiler")
local platform      = require("base/platform")

-- import module
function project._api_import(env, module)

    -- import 
    return require("module/" .. module)
end

-- the current os is belong to the given os?
function project._api_os(env, ...)

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
function project._api_modes(env, ...)

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
function project._api_plats(env, ...)

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
function project._api_archs(env, ...)

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
function project._api_kinds(env, ...)

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
function project._api_options(env, ...)

    -- some options are enabled?
    for _, o in ipairs(table.join(...)) do
        if o and type(o) == "string" and config.get(o) then
            return true
        end
    end
end

-- get all pathes and translate it 
function project._api_get_pathes(...)

    -- check
    assert(project._CURDIR)

    -- get all pathes
    local pathes = table.join(...)

    -- translate the relative path 
    local results = {}
    for _, p in ipairs(pathes) do
        if not p:find("^%s-%$%(.-%)") and not path.is_absolute(p) then
            table.insert(results, path.relative(path.absolute(p, project._CURDIR), project._PROJECT_DIR))
        else
            table.insert(results, p)
        end
    end

    -- ok?
    return results
end

-- add c function
function project._api_add_cfunc(env, module, alias, links, includes, cfunc)

    -- check
    assert(env and cfunc)

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

    -- make option
    env.add_option(name)
    env.set_option_category("cfuncs")
    env.add_option_cfuncs(cfunc)
    if links then env.add_option_links(links) end
    if includes then env.add_option_cincludes(includes) end
    env.add_option_defines_h_if_ok(define)

    -- add this option 
    env.add_options(name)
end

-- add c functions
function project._api_add_cfuncs(env, module, links, includes, ...)

    -- check
    assert(env)

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

        -- make option
        env.add_option(name)
        env.set_option_category("cfuncs")
        env.add_option_cfuncs(cfunc)
        if links then env.add_option_links(links) end
        if includes then env.add_option_cincludes(includes) end
        env.add_option_defines_h_if_ok(define)

        -- add this option 
        env.add_options(name)
    end
end

-- add c++ function
function project._api_add_cxxfunc(env, module, alias, links, includes, cxxfunc)

    -- check
    assert(env and cxxfunc)

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

    -- make option
    env.add_option(name)
    env.set_option_category("cxxfuncs")
    env.add_option_cxxfuncs(cxxfunc)
    if links then env.add_option_links(links) end
    if includes then env.add_option_cxxincludes(includes) end
    env.add_option_defines_h_if_ok(define)

    -- add this option 
    env.add_options(name)
end

-- add c++ functions
function project._api_add_cxxfuncs(env, module, links, includes, ...)

    -- check
    assert(env and module)

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

        -- make option
        env.add_option(name)
        env.set_option_category("cxxfuncs")
        env.add_option_cxxfuncs(cxxfunc)
        if links then env.add_option_links(links) end
        if includes then env.add_option_cxxincludes(includes) end
        env.add_option_defines_h_if_ok(define)

        -- add this option 
        env.add_options(name)
    end
end

-- add target 
function project._api_add_target(env, name)

    -- check
    assert(env and name)

    -- the targets
    local targets = env._CONFIGS._TARGETS
    assert(targets)

    -- init the target scope
    targets[name] = targets[name] or {}

    -- switch to this target scope
    env._TARGET = targets[name]
end

-- add option 
function project._api_add_option(env, name)

    -- check
    assert(env and name)

    -- the options
    local options = env._CONFIGS._OPTIONS
    assert(options)

    -- init the option scope
    options[name] = options[name] or {}

    -- switch to this option scope
    env._OPTION = options[name]
end

-- load all subprojects from the given directories
function project._api_add_subdirs(env, ...)

    -- check
    assert(env)

    -- init mtime for files
    project._MTIMES = project._MTIMES or {}

    -- save the current project file directory
    local curdir = project._CURDIR

    -- get all subdirs 
    local subdirs = project._api_get_pathes(...)

    -- match all subdirs
    local subdirs_matched = {}
    for _, subdir in ipairs(subdirs) do
        local dirs = os.match(subdir, true)
        if dirs then table.join2(subdirs_matched, dirs) end
    end

    -- done
    for _, subdir in ipairs(subdirs_matched) do
        if subdir and type(subdir) == "string" then

            -- the project file
            local file = subdir .. "/xmake.lua"
            if not path.is_absolute(file) then
                file = path.absolute(file, xmake._PROJECT_DIR)
            end

            -- update the current project file directory
            project._CURDIR = path.directory(file)

            -- load the project script
            local script = loadfile(file)
            if script then

                -- bind environment
                setfenv(script, env)

                -- done the project script
                local ok, errors = pcall(script)
                if not ok then
                    utils.error(errors)
                    assert(false)
                end

                -- get mtime of the file
                project._MTIMES[path.relative(file, xmake._PROJECT_DIR)] = os.mtime(file)
            end
        end
    end

    -- restore the current project file directory
    project._CURDIR = curdir

end

-- load all subprojects from the given files
function project._api_add_subfiles(env, ...)

    -- check
    assert(env)

    -- init mtime for files
    project._MTIMES = project._MTIMES or {}

    -- save the current project file directory
    local curdir = project._CURDIR

    -- get all subfiles 
    local subfiles = project._api_get_pathes(...)

    -- match all subfiles
    local subfiles_matched = {}
    for _, subfile in ipairs(subfiles) do
        local files = os.match(subfile)
        if files then table.join2(subfiles_matched, files) end
    end

    -- done
    for _, file in ipairs(subfiles_matched) do
        if file and type(file) == "string" then

            -- the project file
            if not path.is_absolute(file) then
                file = path.absolute(file, xmake._PROJECT_DIR)
            end

            -- update the current project file directory
            project._CURDIR = path.directory(file)

            -- load the project script
            local script = loadfile(file)
            if script then

                -- bind environment
                setfenv(script, env)

                -- done the project script
                local ok, errors = pcall(script)
                if not ok then
                    utils.error(errors)
                    assert(false)
                end

                -- get mtime of the file
                project._MTIMES[path.relative(file, xmake._PROJECT_DIR)] = os.mtime(file)
            end
        end
    end

    -- restore the current project file directory
    project._CURDIR = curdir
end

-- load all packages from the given directories
function project._api_add_pkgdirs(env, ...)

    -- get all directories
    local pkgdirs = {}
    local dirs = table.join(...)
    for _, dir in ipairs(dirs) do
        table.insert(pkgdirs, dir .. "/*.pkg")
    end

    -- add all packages
    project._api_add_subdirs(env, pkgdirs)
end

-- set configure values
function project._api_set_values(scope, name, ...)

    -- check
    assert(scope and name)

    -- update values
    scope[name] = {}
    table.join2(scope[name], ...)
end

-- add configure values
function project._api_add_values(scope, name, ...)

    -- check
    assert(scope and name)

    -- append values
    scope[name] = scope[name] or {}
    table.join2(scope[name], ...)
end

-- set configure pathes
function project._api_set_pathes(scope, name, ...)

    -- check
    assert(scope and name)

    -- update pathes
    scope[name] = {}
    table.join2(scope[name], project._api_get_pathes(...))
end

-- add configure pathes
function project._api_add_pathes(scope, name, ...)

    -- check
    assert(scope and name)

    -- append pathes
    scope[name] = scope[name] or {}
    table.join2(scope[name], project._api_get_pathes(...))
end

-- filter the configure value
function project._filter(values)

    -- check
    assert(values)

    -- filter all
    local newvals = {}
    for _, v in ipairs(utils.wrap(values)) do
        if type(v) == "string" then
            v = v:gsub("%$%((.-)%)",    function (w) 
                                            
                                            -- is upper?
                                            local isupper = false
                                            local c = string.char(w:byte())
                                            if c >= 'A' and c <= 'Z' then isupper = true end

                                            -- attempt to get it directly from the configure
                                            local r = config.get(w)
                                            if not r or type(r) ~= "string" then 

                                                -- attempt to get it from the configure and the lower key
                                                w = w:lower()
                                                r = config.get(w)
                                                if not r or type(r) ~= "string" then 
                                                    
                                                    -- get the other keys
                                                    if w == "projectdir" then r = xmake._PROJECT_DIR
                                                    elseif w == "os" then r = platform.os()
                                                    end 
                                                end
                                            end

                                            -- upper?
                                            if r and type(r) == "string" and isupper then
                                                r = r:upper() 
                                            end

                                            -- ok?
                                            return r
                                        end)
        end
        table.insert(newvals, v)
    end

    -- ok?
    return newvals
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

-- make targets from the project file
function project._make_targets(configs)

    -- check
    assert(configs and configs._TARGETS)
  
    -- init 
    project._TARGETS = project._TARGETS or {}
    local targets = project._TARGETS

    -- make all targets
    for k, v in pairs(configs._TARGETS) do
        targets[k] = v
    end

    -- merge the root configures to all targets
    for _, target in pairs(targets) do

        -- merge the setted configures
        for k, v in pairs(configs._SET) do
            if nil == target[k] then
                target[k] = v
            end
        end

        -- merge the added configures 
        for k, v in pairs(configs._ADD) do
            if nil == target[k] then
                target[k] = v
            else
                target[k] = table.join(v, target[k])
            end
        end

        -- remove repeat values and unwrap it
        for k, v in pairs(target) do

            -- remove repeat first
            v = utils.unique(v)

            -- filter values
            v = project._filter(v)

            -- unwrap it if be only one
            v = utils.unwrap(v)

            -- update it
            target[k] = v
        end
    end

    -- init mtime for the project file
    project._MTIMES = project._MTIMES or {}
    project._MTIMES[path.relative(xmake._PROJECT_FILE, xmake._PROJECT_DIR)] = os.mtime(xmake._PROJECT_FILE)

    -- get the mtimes for configure
    local mtimes_config = config.get("__mtimes")
    if mtimes_config then 

        -- check for all project files and we need reconfig and rebuild it if them have been modified
        for file, mtime in pairs(project._MTIMES) do

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
    config.set("__mtimes", project._MTIMES)

    -- reconfig it? we need reprobe it
    if config._RECONFIG then
        project.probe()
        config.clearup()
    end
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

    -- remove repeat values and unwrap it
    for k, v in pairs(opt) do

        -- remove repeat first
        v = utils.unique(v)

        -- filter values
        v = project._filter(v)

        -- unwrap it if be only one
        v = utils.unwrap(v)

        -- update it
        opt[k] = v
    end

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
function project._make_options(configs)

    -- check
    assert(configs and configs._OPTIONS)
  
    -- the source file path
    local cfile     = os.tmpdir() .. "/__checking.c"
    local cxxfile   = os.tmpdir() .. "/__checking.cpp"

    -- the object file path
    local objectfile = os.tmpdir() .. "/" .. rule.filename("__checking", "object")

    -- the target file path
    local targetfile = os.tmpdir() .. "/" .. rule.filename("__checking", "binary")

    -- make all options
    for k, v in pairs(configs._OPTIONS) do

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

-- only load options from the the project file
function project._load_options(file)

    -- check
    assert(file)

    -- load the project script
    local script = loadfile(file)
    if not script then
        return string.format("load %s failed!", file)
    end

    -- set the current project file directory
    project._CURDIR = path.directory(file)

    -- bind the new environment
    local newenv = {_CONFIGS = {_OPTIONS = {}}}
    setmetatable(newenv, {__index = function(tbl, key)
                                        local val = rawget(tbl, key)
                                        if nil == val then val = rawget(_G, key) end
                                        if nil == val then return function(...) end end
                                        return val
                                    end})
    setfenv(script, newenv)

    -- register import
    newenv.import           = function (module) return project._api_import(newenv, module) end

    -- register interfaces for the condition
    newenv.os               = function (...) return project._api_os(newenv, ...) end
    newenv.kinds            = function (...) return project._api_kinds(newenv, ...) end
    newenv.modes            = function (...) return project._api_modes(newenv, ...) end
    newenv.plats            = function (...) return project._api_plats(newenv, ...) end
    newenv.archs            = function (...) return project._api_archs(newenv, ...) end

    -- register interfaces for the option
    newenv.set_option       = function (...) return project._api_add_option(newenv, ...) end
    newenv.add_option       = function (...) return project._api_add_option(newenv, ...) end
  
    -- register interfaces for the subproject files
    newenv.add_subdirs      = function (...) return project._api_add_subdirs(newenv, ...) end
    newenv.add_subfiles     = function (...) return project._api_add_subfiles(newenv, ...) end
    
    -- register interfaces for the functions
    newenv.add_cfunc        = function (...) return project._api_add_cfunc(newenv, ...) end
    newenv.add_cfuncs       = function (...) return project._api_add_cfuncs(newenv, ...) end
    newenv.add_cxxfunc      = function (...) return project._api_add_cxxfunc(newenv, ...) end
    newenv.add_cxxfuncs     = function (...) return project._api_add_cxxfuncs(newenv, ...) end
   
    -- register interfaces for the package files
    newenv.add_pkgdirs      = function (...) return project._api_add_pkgdirs(newenv, ...) end
    newenv.add_pkgs         = function (...) return project._api_add_subdirs(newenv, ...) end
    
    -- register interfaces for setting option values
    local interfaces =  {   "enable"
                        ,   "showmenu"
                        ,   "category"
                        ,   "warnings"
                        ,   "optimize"
                        ,   "languages"
                        ,   "description"} 

    for _, interface in ipairs(interfaces) do
        newenv["set_option_" .. interface] = function (...) return project._api_set_values(newenv._OPTION, interface, ...) end
    end

    -- register interfaces for adding option values
    interfaces =        {   "links" 
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
                        ,   "undefines_h_if_ok"} 

    for _, interface in ipairs(interfaces) do
        newenv["add_option_" .. interface] = function (...) return project._api_add_values(newenv._OPTION, interface, ...) end
    end

    -- register interfaces for adding option pathes
    interfaces =        {   "linkdirs" 
                        ,   "includedirs"} 

    for _, interface in ipairs(interfaces) do
        newenv["add_option_" .. interface] = function (...) return project._api_add_pathes(newenv._OPTION, interface, ...) end
    end

    -- done the project script
    local ok, errors = pcall(script)
    if not ok then
        return nil, errors
    end

    -- get the project configure
    return newenv._CONFIGS
end

-- only load targets from the project file
function project._load_targets(file)

    -- check
    assert(file)

    -- load the project script
    local script = loadfile(file)
    if not script then
        return string.format("load %s failed!", file)
    end

    -- set the current project file directory
    project._CURDIR = path.directory(file)

    -- bind the new environment
    local newenv = {_CONFIGS = {_SET = {}, _ADD = {}, _TARGETS = {}}}
    setmetatable(newenv, {__index = function(tbl, key)
                                        local val = rawget(tbl, key)
                                        if nil == val then val = rawget(_G, key) end
                                        if nil == val and type(key) == "string" and (key:startswith("add_option") or key:startswith("set_option")) then
                                            return function(...) end 
                                        end
                                        return val
                                    end})
    setfenv(script, newenv)

    -- register import
    newenv.import           = function (module) return project._api_import(newenv, module) end

    -- register interfaces for the condition
    newenv.os               = function (...) return project._api_os(newenv, ...) end
    newenv.kinds            = function (...) return project._api_kinds(newenv, ...) end
    newenv.modes            = function (...) return project._api_modes(newenv, ...) end
    newenv.plats            = function (...) return project._api_plats(newenv, ...) end
    newenv.archs            = function (...) return project._api_archs(newenv, ...) end
    newenv.options          = function (...) return project._api_options(newenv, ...) end

    -- register interfaces for the target
    newenv.set_target       = function (...) return project._api_add_target(newenv, ...) end
    newenv.add_target       = function (...) return project._api_add_target(newenv, ...) end
   
    -- register interfaces for the subproject files
    newenv.add_subdirs      = function (...) return project._api_add_subdirs(newenv, ...) end
    newenv.add_subfiles     = function (...) return project._api_add_subfiles(newenv, ...) end
        
    -- register interfaces for the functions
    newenv.add_cfunc        = function (...) return project._api_add_cfunc(newenv, ...) end
    newenv.add_cfuncs       = function (...) return project._api_add_cfuncs(newenv, ...) end
    newenv.add_cxxfunc      = function (...) return project._api_add_cxxfunc(newenv, ...) end
    newenv.add_cxxfuncs     = function (...) return project._api_add_cxxfuncs(newenv, ...) end
   
    -- register interfaces for the package files
    newenv.add_pkgdirs      = function (...) return project._api_add_pkgdirs(newenv, ...) end
    newenv.add_pkgs         = function (...) return project._api_add_subdirs(newenv, ...) end
    
    -- register interfaces for setting values
    local interfaces =  {   "kind"
                        ,   "config_h_prefix"
                        ,   "version"
                        ,   "strip"
                        ,   "options"
                        ,   "symbols"
                        ,   "warnings"
                        ,   "optimize"
                        ,   "languages"
                        ,   "runscript"
                        ,   "installscript"
                        ,   "packagescript"} 

    for _, interface in ipairs(interfaces) do
        newenv["set_" .. interface] = function (...) return project._api_set_values(newenv._TARGET or newenv._CONFIGS._SET, interface, ...) end
    end
 
    -- register interfaces for setting pathes
    local interfaces =  {   "headerdir" 
                        ,   "targetdir" 
                        ,   "objectdir" 
                        ,   "config_h"} 

    for _, interface in ipairs(interfaces) do
        newenv["set_" .. interface] = function (...) return project._api_set_pathes(newenv._TARGET or newenv._CONFIGS._SET, interface, ...) end
    end

    -- register interfaces for adding values
    interfaces =        {   "deps"
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
                        ,   "vectorexts"} 
    for _, interface in ipairs(interfaces) do
        newenv["add_" .. interface] = function (...) return project._api_add_values(newenv._TARGET or newenv._CONFIGS._ADD, interface, ...) end
    end

    -- register interfaces for adding pathes
    interfaces =        {   "files"
                        ,   "headers" 
                        ,   "linkdirs" 
                        ,   "includedirs"} 
    for _, interface in ipairs(interfaces) do
        newenv["add_" .. interface] = function (...) return project._api_add_pathes(newenv._TARGET or newenv._CONFIGS._ADD, interface, ...) end
    end

    -- done the project script
    local ok, errors = pcall(script)
    if not ok then
        return nil, errors
    end

    -- get the project configure
    return newenv._CONFIGS
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

    -- load the options from the the project file
    local configs, errors = project._load_options(xmake._PROJECT_FILE)
    if not configs then
        return errors
    end

    -- make the options from the the project file
    project._make_options(configs)
end

-- load the project 
function project.load()

    -- load the targets from the the project file
    local configs, errors = project._load_targets(xmake._PROJECT_FILE)
    if not configs then
        return errors
    end

    -- make the targets from the the project file
    project._make_targets(configs)
end

-- reload the project
function project.reload()

    -- clear it first
    project._MTIMES     = nil
    project._TARGETS    = nil
    project._CONFILES   = nil
    project._CURDIR     = nil

    -- load it
    return project.load()
end

-- dump the current configure
function project.dump()
    
    -- check
    assert(project._TARGETS)

    -- dump
    if xmake._OPTIONS.verbose then
        utils.dump(project._TARGETS)
    end
   
end

-- make the configure file for the given target
function project.makeconf(target_name)

    -- init files
    project._CONFILES = project._CONFILES or {}

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
    project._CONFILES = nil
 
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

    -- attempt to load project configure
    local configs = nil
    local errors = nil
    local projectfile = xmake._PROJECT_FILE
    if projectfile and os.isfile(projectfile) then
        configs, errors = project._load_options(projectfile)
    end

    -- failed?
    if not configs then
        if errors then utils.error(errors) end
        return {}
    end

    -- the options
    local options = configs._OPTIONS 
    if not options then return {} end

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
                    default = utils.unwrap(opt.enable)
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
                    table.insert(menu, {nil, name, "kv", default, utils.unwrap(opt.description)})
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
