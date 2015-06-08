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
local preprocessor  = require("base/preprocessor")

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

    -- load the switches
    local switches = {}
    if target.switches then
        for _, switch in ipairs(utils.wrap(target.switches)) do
            table.insert(switches, switch)
        end
    end
    if target.switchfiles then
        for _, switchfile in ipairs(utils.wrap(target.switchfiles)) do
            if not path.is_absolute(switchfile) then
                switchfile = path.absolute(switchfile, xmake._PROJECT_DIR)
            end
            local newenv, errors = preprocessor.loadfile(switchfile, "switches", {"defines"})
            if newenv and newenv._CONFIGS then
                if newenv._CONFIGS.defines then
                    for _, switch in ipairs(newenv._CONFIGS.defines) do
                        table.insert(switches, switch)
                    end
                end
            else
                -- error
                utils.error(errors)
                assert(false)
            end
        end
    end

    -- make the switches
    if #switches ~= 0 then
        file:write("// switches\n")
        for _, switch in ipairs(switches) do
            file:write(string.format("#define %s_%s\n", prefix, switch))
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

-- make the given configure to scope
function project._make_configs(scope, configs)

    -- check
    assert(configs)

    -- the current mode
    local mode = config.get("mode")
    assert(mode)

    -- the current platform
    local plat = config.get("plat")
    assert(plat)

    -- done
    for k, v in pairs(configs) do
        
        -- check
        assert(type(k) == "string")

        -- enter the target configure?
        if k == "_TARGET" then
 
            -- the current 
            local current = project._CURRENT

            -- init all targets
            for _k, _v in pairs(v) do

                -- init target scope first
                current[_k] = current[_k] or {}

                -- make the target configure to this scope
                project._make_configs(current[_k], _v)
            end

        -- enter the platform configure?
        elseif k == "_PLATFORMS" then

            -- append configure to scope for the current mode
            for _k, _v in pairs(v) do
                if _k == plat then
                    project._make_configs(scope, _v)
                end
            end

        -- enter the mode configure?
        elseif k == "_MODES" then

            -- append configure to scope for the current mode
            for _k, _v in pairs(v) do
                if _k == mode then
                    project._make_configs(scope, _v)
                end
            end

        -- append configure to scope
        elseif scope and not k:startswith("_") and k:endswith("s") then

            -- append all 
            scope[k] = scope[k] or {}
            table.join2(scope[k], v)

        -- replace configure to scope
        elseif scope and not k:startswith("_") then
            
            -- the configure item
            scope[k] = scope[k] or {}
            local item = scope[k]

            -- wrap it first
            local values = utils.wrap(v)
            if #values > 1 then
                utils.error("the %s cannot have multiple values in xmake.xproj!", k)
                assert(false)
            end

            -- replace it
            item[1] = values[1]
        end
    end
end

-- make values for switches
function project._make_for_switches(target, values)

    -- check
    assert(values)

    -- wrap values first
    values = utils.wrap(values)

    -- done
    local newvals = {}
    for _, v in ipairs(values) do

        -- done script
        v = v:gsub("%[(.*)%]",  function (w) 

                                    -- load the script
                                    local script = assert(loadstring("return " .. w))

                                    -- bind the envirnoment
                                    setfenv(script, target)

                                    -- ok?
                                    return script() or ""
                                end)

        -- insert new value
        if v and type(v) == "string" and #v ~= 0 then
            table.insert(newvals, v)
        end
    end

    -- ok?
    return newvals
end

-- init switches
function project._init_switches(target)
        
    -- make switches
    target._SWITCHES = target._SWITCHES or {}

    -- _if x return v
    target["_if"] = function (x, v)

        if x and type(x) == "boolean" then return v end
        return nil
    end

    -- _if x return a else return b
    target["_ifelse"] = function (x, a, b)

        if x and type(x) == "boolean" then return a end
        return b
    end

    -- init switches
    if target.switches then
        for _, switch in ipairs(target.switches) do
            target._SWITCHES[switch] = true
        end
    end

    -- load switches from the xxxx.xswf
    if target.switchfiles then
        for _, switchfile in ipairs(target.switchfiles) do
            if not path.is_absolute(switchfile) then
                switchfile = path.absolute(switchfile, xmake._PROJECT_DIR)
            end
            local newenv, errors = preprocessor.loadfile(switchfile, "switches", {"defines"})
            if newenv and newenv._CONFIGS then
                if newenv._CONFIGS.defines then
                    for _, switch in ipairs(newenv._CONFIGS.defines) do
                        target._SWITCHES[switch] = true
                    end
                end
            else
                -- error
                utils.error(errors)
                assert(false)
            end
        end
    end

    -- attempt to get it from the switches
    setmetatable(target, 
    {
        __index = function(tbl, key)

            local switches = rawget(tbl, "_SWITCHES")
            if switches and switches[key] then
                return switches[key]
            end
            return rawget(tbl, key)
        end
    })

end

-- exit switches
function project._exit_switches(target)

    -- remove it
    target._SWITCHES = nil

    -- remove if and ifelse
    target["_if"] = nil
    target["_ifelse"] = nil
end
        
-- make the current project configure
function project._make()

    -- the configs
    local configs = project._CONFIGS
    assert(configs)
  
    -- init current
    project._CURRENT = project._CURRENT or {}

    -- make the current configure
    local root = {}
    project._make_configs(root, configs)

    -- merge and remove repeat values and unwrap it
    for _, target in pairs(project._CURRENT) do

        -- merge the root configure to all targets
        for k, v in pairs(root) do
            if not target[k] then
                -- insert it
                target[k] = v
            elseif not k:startswith("_") and k:endswith("s") then
                -- join root and target and update it
                target[k] = table.join(v, target[k])
            end
        end

        -- init switches
        project._init_switches(target)

        -- remove repeat values and unwrap it
        for k, v in pairs(target) do

            if k and not k:startswith("_") then

                -- make values for switches
                v = project._make_for_switches(target, v)

                -- remove repeat first
                v = utils.unique(v)

                -- unwrap it if be only one
                v = utils.unwrap(v)

                -- update it
                target[k] = v
            end
        end

        -- exit switches 
        project._exit_switches(target)
    end
end

-- get the current configure for targets
function project.targets()

    -- check
    assert(project._CURRENT)

    -- return it
    return project._CURRENT
end

-- load xproj
function project.loadxproj(file)

    -- check
    assert(file)

    -- init configures
    local configures = {    "kind"
                        ,   "deps"
                        ,   "files"
                        ,   "links" 
                        ,   "headers" 
                        ,   "headerdir" 
                        ,   "targetdir" 
                        ,   "objectdir" 
                        ,   "linkdirs" 
                        ,   "includedirs" 
                        ,   "configfile"
                        ,   "version"
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
                        ,   "switches"
                        ,   "switchfiles"
                        ,   "strip"
                        ,   "symbols"
                        ,   "warnings"
                        ,   "optimize"
                        ,   "language"
                        ,   "vectorexts"} 

    -- init filter
    local filter =  function (env, v) 
                        if v == "buildir" then
                            return config.get("buildir")
                        elseif v == "projectdir" then
                            return xmake._PROJECT_DIR
                        end
                        return v 
                    end

    -- init import 
    local import = function (name)

        -- import configs?
        if name == "configs" then

            -- init configs
            local configs = {}

            -- get the config for the current target
            for k, v in pairs(config._CURRENT) do
                configs[k] = v
            end

            -- init the project directory
            configs.projectdir = xmake._OPTIONS.project

            -- import it
            return configs
        end

    end

    -- load and execute the xmake.xproj
    local newenv, errors = preprocessor.loadfile(file, "project", configures, {"target", "platforms", "modes"}, filter, import)
    if newenv and newenv._CONFIGS then
        -- ok
        project._CONFIGS = newenv._CONFIGS
    elseif errors then
        -- error
        return errors
    else
        -- error
        return string.format("load %s failed!", file)
    end

    -- make the current project configure
    project._make()

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
