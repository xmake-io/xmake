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
function config._make(configs)

    -- check
    assert(configs and configs.plat and configs.arch and configs._PLATS)
  
    -- the options
    local options = xmake._OPTIONS
    assert(options)

    -- the configs for platform
    local configs_plat = configs._PLATS[configs.plat]
    assert(configs_plat)

    -- the configs for architecture
    local configs_arch = configs_plat[configs.arch]
    assert(configs_arch)

    -- init current target configure
    local current = {plat = configs.plat, arch = configs.arch, __rebuild = configs.__rebuild}

    -- get configs from the global configure first
    if global._CURRENT then
        for k, v in pairs(global._CURRENT) do 
            current[k] = v
        end
    end

    -- get configs from all targets 
    for k, v in pairs(configs_arch) do 
        if type(k) == "string" and not k:find("^_%u+") then
            current[k] = v
        end
    end

    -- get configs from the current target 
    if configs_arch._TARGETS and current.target ~= "all" then

        -- get the target config
        local target_config = configs_arch._TARGETS[current.target]
        if target_config then

            -- merge it
            for k, v in pairs(target_config) do
                current[k] = v
            end
        end
    end

    -- ok?
    return current
end

-- get the configure file
function config._file()
 
    -- get it
    return config.directory() .. "/xmake.conf"
end

-- need configure?
function config._need(name)
    return  name and 
            name ~= "plat" and 
            name ~= "arch" and 
            name ~= "target" and 
            name ~= "file" and 
            name ~= "project" and 
            name ~= "verbose" and 
            name ~= "clean"
end

-- get the current target scope
function config._target()
 
    -- the options
    local options = xmake._OPTIONS
    assert(options)

    -- check
    local configs = config._CONFIGS
    assert(configs and configs.plat and configs.arch)
  
    -- the target name
    local name = options.target or options._DEFAULTS.target
    assert(name and type(name) == "string")

    -- init the configs for platform
    configs._PLATS = configs._PLATS or {}
    configs._PLATS[configs.plat] = configs._PLATS[configs.plat] or {}
    local configs_plat = configs._PLATS[configs.plat]

    -- init the configs for architecture
    configs_plat[configs.arch] = configs_plat[configs.arch] or {}
    local configs_arch = configs_plat[configs.arch]

    -- init targets
    configs_arch._TARGETS = configs_arch._TARGETS or {}
    if name ~= "all" then
        configs_arch._TARGETS[name] = configs_arch._TARGETS[name] or {}
    end

    -- for all targets?
    if name == "all" then
        return configs_arch
    elseif configs_arch._TARGETS then
        -- get it
        return configs_arch._TARGETS[name]
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
    assert(config._CURRENT and config._CONFIGS and name)

    -- set platform or rebuild?
    if name == "plat" or name == "__rebuild" then

        config._CONFIGS[name] = value
        config._CURRENT[name] = value

    -- set architecture?
    elseif name == "arch" then

        -- the configs
        local configs = config._CONFIGS
        if configs.arch == "auto" then

            -- the configs for platform
            local configs_plat = configs._PLATS[configs.plat]
            assert(configs_plat)

            -- update configs of the auto architecture
            configs_plat[value] = configs_plat["auto"]
            configs_plat["auto"] = nil

        end

        config._CONFIGS.arch = value
        config._CURRENT.arch = value

    -- set others
    else
        -- get the current target
        local target = config._target()
        assert(target)

        -- set it to the current target configure for saving to file
        target[name] = value

        -- set it to the current configure
        config._CURRENT[name] = value
    end
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

                -- make the current target configs
                local current = config._make(configs)

                -- clear configs and mark as "rebuild" and "reconfig" if the host has been changed
                if current and current.host ~= xmake._HOST then

                    -- clear configs and mark as "rebuild"
                    config._CONFIGS = { __rebuild = true }

                    -- mark as "reconfig" if the current action is not "config"
                    if options._ACTION ~= "config" then 
                        config._RECONFIG = true
                    end
                end

                -- clear configs and mark as "rebuild" if the plat has been changed
                if current and current.plat and options.plat and current.plat ~= options.plat then

                    -- clear architecture and mark as "rebuild"
                    configs.arch = nil
                    configs.__rebuild = true
                end

                -- mark as "rebuild" if the arch has been changed
                if current and current.arch and options.arch and current.arch ~= options.arch then

                    -- mark as "rebuild"
                    configs.__rebuild = true
                end

                -- mark as "rebuild" if the mode has been changed
                if current and current.mode and options.mode and current.mode ~= options.mode then

                    -- mark as "rebuild"
                    configs.__rebuild = true
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

    -- init the platform 
    configs.plat = options.plat or configs.plat or options._DEFAULTS.plat or option.defaults("config").plat
    assert(configs.plat)

    -- init the architecture 
    configs.arch = options.arch or configs.arch or options._DEFAULTS.arch or option.defaults("config").arch
    assert(configs.arch)

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

    -- make the current configure
    config._CURRENT = config._make(configs)

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

-- reload configure
function config.reload()

    -- clear the old configure
    config._CURRENT = nil
    config._CONFIGS = nil

    -- load it
    return config.load()
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
