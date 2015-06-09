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

-- define module: config
local project = project or {}

-- load modules
local path          = require("base/path")
local utils         = require("base/utils")
local table         = require("base/table")
local config        = require("base/config")

-- the current mode is belong to the given modes?
function project._api_modes(env, ...)

    -- get the current mode
    local mode = config.get("mode")
    assert(mode)

    -- exists this mode?
    for _, m in ipairs(utils.wrap(...)) do
        if m and type(m) == "string" and m == mode then
            return true
        end
    end
end

-- the current platform is belong to the given platforms?
function project._api_plats(env, ...)

    -- get the current platform
    local plat = config.get("plat")
    assert(plat)

    -- exists this platform?
    for _, p in ipairs(utils.wrap(...)) do
        if p and type(p) == "string" and p == plat then
            return true
        end
    end
end

-- the current platform is belong to the given architectures?
function project._api_archs(env, ...)

    -- get the current architecture
    local arch = config.get("arch")
    assert(arch)

    -- exists this architecture?
    for _, a in ipairs(utils.wrap(...)) do
        if a and type(a) == "string" and a == arch then
            return true
        end
    end
end

-- load all subprojects from the given directories
function project._api_subdirs(env, ...)

    -- check
    assert(env)

    -- done
    for _, subdir in ipairs(utils.wrap(...)) do
        if subdir and type(subdir) == "string" then

            -- the project file
            local file = subdir .. "/xmake.lua"
            if not path.is_absolute(file) then
                file = path.absolute(file, xmake._PROJECT_DIR)
            end

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
            end
        end
    end
end

-- load all subprojects from the given files
function project._api_subfiles(env, ...)

    -- check
    assert(env)

    -- done
    for _, subfile in ipairs(utils.wrap(...)) do
        if subfile and type(subfile) == "string" then

            -- the project file
            if not path.is_absolute(subfile) then
                subfile = path.absolute(subfile, xmake._PROJECT_DIR)
            end

            -- load the project script
            local script = loadfile(subfile)
            if script then

                -- bind environment
                setfenv(script, env)

                -- done the project script
                local ok, errors = pcall(script)
                if not ok then
                    utils.error(errors)
                    assert(false)
                end
            end
        end
    end
end

-- switch to the given target 
function project._api_target(env, name)

    -- check
    assert(env and name)

    -- the configs
    local configs = env._CONFIGS
    assert(configs)

    -- init the target scope
    configs[name] = configs[name] or {}

    -- switch to this targe scope
    env._TARGET = configs[name]
end

-- the single configure value 
function project._api_value(env, name, value)

    -- check
    assert(env and name and value)

    -- get the current scope
    local scope = env._TARGET or env._CONFIGS._ROOT
    assert(scope)

    -- update value
    scope[name] = value
end

-- the multiple configure values
function project._api_values(env, name, ...)

    -- check
    assert(env and name)

    -- get the current scope
    local scope = env._TARGET or env._CONFIGS._ROOTS
    assert(scope)

    -- append values
    scope[name] = scope[name] or {}
    table.join2(scope[name], ...)
end

-- filter the configure value
function project._filter(values)

    -- check
    assert(values)

    -- filter all
    local newvals = {}
    for _, v in ipairs(utils.wrap(values)) do
        v = v:gsub("%$%((.*)%)",    function (w) 
                                        if w == "buildir" then
                                            return config.get("buildir")
                                        elseif w == "projectdir" then
                                            return xmake._PROJECT_DIR
                                        end 
                                    end)
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
    local configfile = target.configfile
    if not configfile then 
        return true
    end

    -- translate file path
    if not path.is_absolute(configfile) then
        configfile = path.absolute(configfile, xmake._PROJECT_DIR)
    else
        configfile = path.translate(configfile)
    end

    -- the prefix
    local prefix = target_name:upper() .. "_CONFIG"
    
    -- open the file
    local file = io.open(configfile, "w")

    -- make the head
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
        file:write(string.format("#define %s_VERSION_BUILD %d\n", prefix, os.date("%Y%m%d%H%M", os.time())))
        file:write("\n")
    end

    -- make the undefines
    if target.undefines then
        file:write("// undefines\n")
        for _, undefine in ipairs(utils.wrap(target.undefines)) do
            file:write(string.format("#undef %s\n", undefine))
        end
        file:write("\n")
    end

    -- make the defines
    if target.defines then
        file:write("// defines\n")
        for _, define in ipairs(utils.wrap(target.defines)) do
            file:write(string.format("#define %s\n", define))
        end
        file:write("\n")
    end

    -- make the tail
    file:write("#endif\n")

    -- exit the file
    file:close()

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

-- make the current project configure
function project._make(configs)

    -- check
    assert(configs)
  
    -- init 
    project._CURRENT = project._CURRENT or {}
    local current = project._CURRENT

    -- make all targets
    for k, v in pairs(configs) do
        if not k:startswith("_") then
            current[k] = v
        end
    end

    -- merge the root configures to all targets
    for _, target in pairs(current) do

        -- merge the single root configure 
        for k, v in pairs(configs._ROOT) do
            if not target[k] then
                target[k] = v
            end
        end

        -- merge the multiple root configure 
        for k, v in pairs(configs._ROOTS) do
            if not target[k] then
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
end

-- get the current configure for targets
function project.targets()

    -- check
    assert(project._CURRENT)

    -- return it
    return project._CURRENT
end

-- load the project file
function project.load(file)

    -- check
    assert(file)

    -- load the project script
    local script = loadfile(file)
    if not script then
        return string.format("load %s failed!", file)
    end

    -- bind the new environment
    local newenv = {_CONFIGS = {_ROOT = {}, _ROOTS = {}}}
    setmetatable(newenv, {__index = _G})
    setfenv(script, newenv)

    -- register interfaces for the condition
    newenv.modes        = function (...) return project._api_modes(newenv, ...) end
    newenv.plats        = function (...) return project._api_plats(newenv, ...) end
    newenv.archs        = function (...) return project._api_archs(newenv, ...) end

    -- register interfaces for the target
    newenv.target       = function (...) return project._api_target(newenv, ...) end
    
    -- register interfaces for the subproject files
    newenv.subdirs      = function (...) return project._api_subdirs(newenv, ...) end
    newenv.subfiles     = function (...) return project._api_subfiles(newenv, ...) end
    
    -- register interfaces for the single value
    local interfaces =  {   "kind"
                        ,   "headerdir" 
                        ,   "targetdir" 
                        ,   "objectdir" 
                        ,   "configfile"
                        ,   "version"
                        ,   "strip"
                        ,   "optimize"
                        ,   "language"} 
    for _, interface in ipairs(interfaces) do
        newenv[interface] = function (value) return project._api_value(newenv, interface, value) end
    end

    -- register interfaces for the multiple values
    interfaces =        {   "deps"
                        ,   "files"
                        ,   "links" 
                        ,   "headers" 
                        ,   "linkdirs" 
                        ,   "includedirs" 
                        ,   "cflags" 
                        ,   "cxflags" 
                        ,   "cxxflags" 
                        ,   "mflags" 
                        ,   "mxflags" 
                        ,   "mxxflags" 
                        ,   "ldflags" 
                        ,   "shflags" 
                        ,   "defines"
                        ,   "undefines"
                        ,   "symbols"
                        ,   "warnings"
                        ,   "vectorexts"} 
    for _, interface in ipairs(interfaces) do
        newenv[interface] = function (...) return project._api_values(newenv, interface, ...) end
    end

    -- done the project script
    local ok, errors = pcall(script)
    if not ok then
        return errors
    end

    -- make the current project configure
    project._make(newenv._CONFIGS)
end

-- dump the current configure
function project.dump()
    
    -- check
    assert(project._CURRENT)

    -- dump
    if xmake._OPTIONS.verbose then
        utils.dump(project._CURRENT)
    end
   
end

-- make the configure file for the given target
function project.makeconf(target_name)

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
 
    -- ok
    return true
end

-- return module: project
return project
