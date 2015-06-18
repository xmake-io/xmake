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
local os            = require("base/os")
local utils         = require("base/utils")
local option        = require("base/option")
local global        = require("base/global")

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

    -- get configs from the global configure first
    if global._CURRENT then
        for k, v in pairs(global._CURRENT) do 
            current[k] = v
        end
    end

    -- get configs from all targets 
    for k, v in pairs(configs) do 
        if type(k) == "string" and not k:find("^_%u+") then
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

-- get the configure file
function config._file()
 
    -- get it
    return config.directory() .. "/xmake.conf"
end

-- need configure?
function config._need(name)
    return name and name ~= "target" and name ~= "file" and name ~= "project" and name ~= "verbose" and name ~= "clean"
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

    -- the configure has been not loaded
    if not config._CURRENT then return end

    -- the value
    local value = config._CURRENT[name]
    if type(value) == "string" and value == "auto" then
        value = nil
    end

    -- get it
    return value
end

-- set the given configure to the current 
function config.set(name, value)

    -- check
    assert(config._CURRENT and name)

    -- get the current target
    local target = config._target()
    assert(target)

    -- set it to the current target configure for saving to file
    target[name] = value

    -- set it to the current configure
    config._CURRENT[name] = value
end

-- get the configure directory
function config.directory()

    -- the directory
    local dir = xmake._PROJECT_DIR .. "/.xmake"

    -- create it directly first if not exists
    if not os.isdir(dir) then
        assert(os.mkdir(dir))
    end

    -- get it
    return dir
end

-- save xmake.conf
function config.save()
    
    -- the configs
    local configs = config._CONFIGS
    assert(configs)

    -- save to the configure file
    return io.save(config._file(), configs) 
end

function config.load()

    -- the options
    local options = xmake._OPTIONS
    assert(options)

    -- check
    assert(option._MENU)
    assert(option._MENU.config)

    -- the target name
    local name = options.target or options._DEFAULTS.target
    if not name then
        return "no given target name!"
    end

    -- does not clean the cached configure?
    if not options.clean then

        -- load and execute the xmake.xconf
        local filepath = config._file()
        if os.isfile(filepath) then
        
            -- load the configure file
            local configs, errors = io.load(filepath)

            -- exists local configures?
            if configs then

                -- save configs
                config._CONFIGS = configs

                -- clear configs and mark as "rebuild" and "reconfig" if the host has been changed
                local target = config._target()
                if target and target.host ~= xmake._HOST then

                    -- clear configs and mark as "rebuild"
                    config._CONFIGS = { __rebuild = true }

                    -- mark as "reconfig" if the current action is not "config"
                    if options._ACTION ~= "config" then 
                        config._RECONFIG = true
                    end
                end

                -- clear configs and mark as "rebuild" if the plat has been changed
                if target and target.plat and options.plat and target.plat ~= options.plat then

                    -- clear configs and mark as "rebuild"
                    config._CONFIGS = { __rebuild = true }
                end

                -- mark as "rebuild" if the arch has been changed
                if target and target.arch and options.arch and target.arch ~= options.arch then

                    -- mark as "rebuild"
                    config._CONFIGS.__rebuild = true
                end

                -- mark as "rebuild" if the mode has been changed
                if target and target.mode and options.mode and target.mode ~= options.mode then

                    -- mark as "rebuild"
                    config._CONFIGS.__rebuild = true
                end
            elseif errors then
                -- error
                utils.error(errors)
            end
        end
    end

    -- init configs if not exists
    if not config._CONFIGS then
        -- clear configs and mark as "rebuild"
        config._CONFIGS = { __rebuild = true }

        -- mark as "reconfig" if the current action is not "config"
        if options._ACTION ~= "config" then 
            config._RECONFIG = true
        end
    end

    -- the configs
    local configs = config._CONFIGS

    -- mark as "rebuild" if clean the cached configure 
    if options.clean then 
        configs.__rebuild = true
    end

    -- init targets
    configs._TARGET = configs._TARGET or {}
    if name ~= "all" then
        configs._TARGET[name] = configs._TARGET[name] or {}
    end

    -- get the current target scope
    local target = config._target()
    assert(target and type(target) == "table")

    -- merge xmake._OPTIONS to target
    if options._ACTION == "config" then
        for k, v in pairs(options) do

            -- check
            assert(type(k) == "string")

            -- skip some options
            if not k:startswith("_") and config._need(k) then

                -- save the option to the target
                target[k] = v
            end
        end
    end

    -- merge the default configure options to target
    local defaults = nil
    if config._RECONFIG then defaults = option.defaults("config")
    elseif options._ACTION == "config" then defaults = options._DEFAULTS
    end
    if defaults then
        for k, v in pairs(defaults) do

            -- check
            assert(type(k) == "string")

            -- skip some options
            if config._need(k) then

                -- save the default option to the target
                if nil == target[k] then
                    target[k] = v
                end
            end
        end
    end

    -- make the current config
    config._make()
end

-- clear up and remove all auto values
function config.clearup()

    -- clear up the current configure
    local current = config._CURRENT
    if current then
        for k, v in pairs(current) do
            if type(v) == "string" and v == "auto" then
                current[k] = nil
            end
        end
    end

    -- clear up the current target configure
    local target = config._target()
    if target then
        for k, v in pairs(target) do
            if type(v) == "string" and v == "auto" then
                target[k] = nil
            end
        end
    end

end

-- dump the current configure
function config.dump()
    
    -- check
    assert(config._CURRENT)

    -- dump
    utils.dump(config._CURRENT, "__%w*", "configure")
   
end

-- return module: config
return config
