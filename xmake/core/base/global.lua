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
-- @file        global.lua
--

-- define module: global
local global = global or {}

-- load modules
local io            = require("base/io")
local os            = require("base/os")
local utils         = require("base/utils")
local option        = require("base/option")

-- make configure
function global._make()

    -- the configs
    local configs = global._CONFIGS
    assert(configs)
   
    -- the options
    local options = xmake._OPTIONS
    assert(options)

    -- init current global configure
    global._CURRENT = global._CURRENT or {}
    local current = global._CURRENT

    -- make current global configure
    for k, v in pairs(configs) do 
        if type(k) == "string" and not k:find("^_%u+") then
            current[k] = v
        end
    end
end

-- get the configure file
function global._file()
    
    -- get it
    return global.directory() .. "/xmake.conf"
end

-- need configure?
function global._need(name)
    return name and name ~= "verbose" and name ~= "clean"
end

-- get the given configure from the current 
function global.get(name)

    -- check
    assert(global._CURRENT)

    -- the value
    local value = global._CURRENT[name]
    if value and value == "auto" then
        value = nil
    end

    -- get it
    return value
end

-- set the given configure to the current 
function global.set(name, value)

    -- check
    assert(global._CURRENT and global._CONFIGS)
    assert(name and type(value) ~= "table")

    -- set it to the current configure
    global._CURRENT[name] = value

    -- set it to the configure for saving to file
    global._CONFIGS[name] = value

end

-- get the global configure directory
function global.directory()

    -- the directory
    local dir = path.translate("~/.xmake")

    -- create it directly first if not exists
    if not os.isdir(dir) then
        assert(os.mkdir(dir))
    end

    -- get it
    return dir
end

-- save xmake.conf
function global.save()
    
    -- the configs
    local configs = global._CONFIGS
    assert(configs)

    -- save to the configure file
    return io.save(global._file(), configs) 
end
 
-- load xmake.conf
function global.load()

    -- the options
    local options = xmake._OPTIONS
    assert(options)

    -- check
    assert(option._MENU)
    assert(option._MENU.global)

    -- get all configure names
    local i = 1
    local configures = {}
    for _, o in ipairs(option._MENU.global.options) do
        local name = o[2]
        if global._need(name) then
            configures[i] = name
            i = i + 1
        end
    end

    -- does not clean the cached configure?
    if not options.clean then

        -- load and execute the xmake.conf
        local filepath = global._file()
        if os.isfile(filepath) then

            -- load the configure file
            local configs, errors = io.load(filepath)

            -- exists local configures?
            if configs then
                -- save configs
                global._CONFIGS = configs
            elseif errors then
                -- error
                utils.error(errors)
            end
        end
    end

    -- init configs
    global._CONFIGS = global._CONFIGS or {}
    local configs = global._CONFIGS

    -- xmake global?
    if options._ACTION == "global" then
        
        -- merge xmake._OPTIONS to the global configure
        for k, v in pairs(options) do

            -- check
            assert(type(k) == "string")

            -- need configure it?
            if not k:startswith("_") and global._need(k) then
                configs[k] = v
            end
        end

        -- merge the default global configure options to the global configure
        local defaults = options._DEFAULTS
        if defaults then
            for k, v in pairs(defaults) do

                -- check
                assert(type(k) == "string")

                -- need configure it?
                if global._need(k) then

                    -- save the default option
                    if nil == configs[k] then
                        configs[k] = v
                    end
                end
            end
        end
    end

    -- make the current global
    global._make()
end

-- clear up and remove all auto values
function global.clearup()

    -- clear up the current configure
    local current = global._CURRENT
    if current then
        for k, v in pairs(current) do
            if v and type(v) and v == "auto" then
                current[k] = nil
            end
        end
    end

    -- clear up the configure
    local configs = global._CONFIGS
    if configs then
        for k, v in pairs(configs) do
            if v and type(v) and v == "auto" then
                configs[k] = nil
            end
        end
    end
end

-- dump the current configure
function global.dump()
    
    -- check
    assert(global._CURRENT)

    -- dump
    utils.dump(global._CURRENT, "__%w*", "configure")
   
end

-- return module: global
return global
