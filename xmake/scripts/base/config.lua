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
-- @file        config.lua
--

-- define module: config
local config = config or {}

-- load modules
local io            = require("base/io")
local utils         = require("base/utils")
local option        = require("base/option")
local preprocessor  = require("base/preprocessor")

-- make the automatic configure
function config._auto(name)

    -- get platform or host
    if name == "plat" or name == "host" then
        return xmake._HOST
    -- get architecture
    elseif name == "arch" then
        return xmake._ARCH
    end

    -- unknown
    utils.error("unknown config: %s", name)
    return "unknown"
end

-- save object with the level
function config._save_with_level(file, object, level)
 
    -- check
    assert(object)

    -- save string
    if type(object) == "string" then  
        file:write(object) 
    -- save boolean
    elseif type(object) == "boolean" then  
        file:write(tostring(object))  
    -- save number 
    elseif type(object) == "number" then  
        file:write(object)  
    -- save table
    elseif type(object) == "table" then  

        -- save head
        file:write(utils.ifelse(level == 0, "config:\n", "\n"))
        for l = 1, level do
            file:write("    ")
        end
        file:write("{\n")  

        -- save body
        for k, v in pairs(object) do  

            -- save _TARGET
            if type(k) == "string" and k == "_TARGET" then

                for _k, _v in pairs(v) do  

                    -- save spaces
                    for l = 0, level do
                        file:write("    ")
                    end

                    -- save key
                    file:write("target: ", _k)  

                    -- save value
                    if not config._save_with_level(file, _v, level + 1) then 
                        return false
                    end

                    -- save newline
                    file:write("\n")
                end

            -- exclude _PARENT
            elseif type(k) ~= "string" or k ~= "_PARENT" then

                -- save spaces
                for l = 0, level do
                    file:write("    ")
                end

                -- save key
                if type(k) == "string" then
                    file:write(k, ": ")  
                end

                -- save value
                if not config._save_with_level(file, v, level + 1) then 
                    return false
                end

                -- save newline
                file:write("\n")
            end
        end  

        -- save tail
        for l = 1, level do
            file:write("    ")
        end
        file:write("}\n")  
    else  
        -- error
        utils.error("invalid object type: %s", type(object))
        return false
    end  

    -- ok
    return true
end

-- save object
function config._save(file, object)

    -- save it
    return config._save_with_level(file, object, 0)
end

-- make configure for the current target
function config._make()

    -- the configs
    local configs = config._CONFIGS
    assert(configs)
   
    -- the options
    local options = xmake._OPTIONS
    assert(options)

    -- init current config
    config._CURRENT = config._CURRENT or {}
    local current = config._CURRENT

    -- init the current target 
    current.target = options.target or options._DEFAULTS.target
    assert(current.target)

    -- get configs from all targets first
    for k, v in pairs(configs) do 
        if type(k) == "string" and not k:startswith("_") then
            current[k] = v
        end
    end

    -- get configs from the current target 
    if configs._TARGET and current.target ~= "all" then

        -- get the target config
        local target_config = configs._TARGET[current.target]
        if target_config then

            -- merge to the current config
            for k, v in pairs(target_config) do
                current[k] = v
            end
        end
    end
end

-- get the current target scope
function config._target()
 
    -- the options
    local options = xmake._OPTIONS
    assert(options)

    -- check
    local configs = config._CONFIGS
    assert(configs)
  
    -- the target name
    local name = options.target or options._DEFAULTS.target
    assert(name and type(name) == "string")

    -- for all targets?
    if name == "all" then
        return configs
    elseif configs._TARGET then
        -- get it
        return configs._TARGET[name]
    end
end

-- get the given configure from the current 
function config.get(name)

    -- check
    assert(config._CURRENT)

    -- get it
    return config._CURRENT[name]
end

-- save xmake.xconf
function config.savexconf()
    
    -- the options
    local options = xmake._OPTIONS
    assert(options)
 
    -- the configs
    local configs = config._CONFIGS
    assert(configs)

    -- open the configure file
    local path = options.project .. "/xmake.xconf"
    local file = io.open(path, "w")
    if not file then
        -- error
        utils.error("open %s failed!", path)
        return false
    end

    -- save configs to file
    if not config._save(file, configs) then
        -- error 
        utils.error("save %s failed!", path)
        file:close()
        return false
    end

    -- close file
    file:close()
   
    -- ok
    return true
end
 
-- load xmake.xconf
function config.loadxconf()

    -- the options
    local options = xmake._OPTIONS
    assert(options and options.project)

    -- check
    assert(option._MENU)
    assert(option._MENU.config)

    -- get all configure names
    local i = 1
    local configures = {}
    for _, o in ipairs(option._MENU.config.options) do
        local name = o[2]
        if name and name ~= "target" and name ~= "file" and name ~= "project" and name ~= "verbose" then
            configures[i] = name
            i = i + 1
        end
    end

    -- load and execute the xmake.xconf
    local path = options.project .. "/xmake.xconf"
    local newenv = preprocessor.loadfile(path, "config", configures, {"target"})

    -- exists local configures?
    if newenv then

        -- save configs
        config._CONFIGS = newenv._CONFIGS

        -- clear configs if the host environment has been changed
        local target = config._target()
        if target and target.host ~= xmake._HOST then
            config._CONFIGS = {}
        end
    end

    -- the target name
    local name = options.target or options._DEFAULTS.target
    assert(name and type(name) == "string")

    -- init configs
    config._CONFIGS = config._CONFIGS or {}
    local configs = config._CONFIGS

    -- init targets
    configs._TARGET = configs._TARGET or {}
    if name ~= "all" then
        configs._TARGET[name] = configs._TARGET[name] or {}
    end

    -- get the current target scope
    local target = config._target()
    assert(target and type(target) == "table")

    -- merge xmake._OPTIONS to target
    for k, v in pairs(options) do

        -- check
        assert(type(k) == "string")

        -- skip some options
        if not k:startswith("_") and k ~= "project" and k ~= "file" and k ~= "verbose" and k ~= "target" then

            -- save the option to the target
            target[k] = v
        end
    end

    -- merge xmake._OPTIONS._DEFAULTS to target
    for k, v in pairs(options._DEFAULTS) do

        -- check
        assert(type(k) == "string")

        -- skip some options
        if k ~= "project" and k ~= "file" and k ~= "verbose" and k ~= "target" then

            -- save the default option to the target
            if not target[k] then

                if v == "auto" then 
                    target[k] = config._auto(k)
                else
                    target[k] = v
                end
            end
        end
    end

    -- make the current config
    config._make()
end

-- dump the current configure
function config.dump()
    
    -- check
    assert(config._CURRENT)

    -- dump
    if xmake._OPTIONS.verbose then
        utils.dump(config._CURRENT)
    end
   
end

-- return module: config
return config
