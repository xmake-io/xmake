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
-- @file        config.lua
--

-- define module
local config = config or {}

-- load modules
local io            = require("base/io")
local os            = require("base/os")
local path          = require("base/path")
local table         = require("base/table")
local utils         = require("base/utils")
local option        = require("base/option")
local global        = require("project/global")

-- get the configure file
function config._file()
    
    -- get it
    return path.join(config.directory(), "xmake.conf")
end

-- get the current given configure
function config.get(name)

    -- get configs
    local configs = config._CONFIGS or {}

    -- get it 
    local value = configs[name]
    if type(value) == "string" and value == "auto" then
        value = nil
    end

    -- get it
    return value
end

-- set the given configure to the current 
function config.set(name, value)

    -- check
    assert(name)

    -- get configs
    local configs = config._CONFIGS or {}
    config._CONFIGS = configs

    -- set it 
    configs[name] = value

end

-- get all options
function config.options()

    -- check
    assert(config._CONFIGS)
         
    -- remove values with "auto" and private item
    local configs = {}
    for name, value in pairs(config._CONFIGS) do
        if not name:find("^_%u+") and (type(value) ~= "string" or value ~= "auto") then
            configs[name] = value
        end
    end

    -- get it
    return configs
end

-- get the configure directory
function config.directory()

    -- get it
    return path.join(xmake._PROJECT_DIR, ".xmake")
end

-- load the project configure
function config.load(targetname)

    -- get the target name
    targetname = targetname or "all"

    -- load configure from the file first
    local filepath = config._file()
    if os.isfile(filepath) then

        -- load it 
        local results, errors = io.load(filepath)

        -- error?
        if not results then
            utils.error(errors)
            return true
        end

        -- merge the target configure first
        if targetname ~= "all" and results._TARGETS then
            for name, value in pairs(table.wrap(results._TARGETS[targetname])) do
                if config.get(name) == nil then
                    config.set(name, value)
                end
            end
        end

        -- merge the root configure 
        for name, value in pairs(results) do
            if config.get(name) == nil then
                config.set(name, value)
            end
        end
    end

    -- ok
    return true
end

-- save the project configure
function config.save(targetname)

    -- get the target name
    targetname = targetname or "all"

    -- load configure from the file first
    local results = {}
    local filepath = config._file()
    if os.isfile(filepath) then
        results = io.load(filepath) or {}
    end

    -- add version
    results.__version = xmake._VERSION_SHORT

    -- update options for the given target
    local target = nil
    if targetname ~= "all" then
        
        -- the targets
        local targets = results._TARGETS or {}
        results._TARGETS = targets

        -- clear target and get it
        targets[targetname] = {}
        target = targets[targetname]
    else

        -- the targets
        local targets = results._TARGETS

        -- clear the root target and get it
        results = {_TARGETS = targets}
        target = results

    end

    -- update target
    for name, value in pairs(config.options()) do
        target[name] = value
    end

    -- save it
    return io.save(config._file(), results) 
end

-- init the config
function config.init()

    -- clear it
    config._CONFIGS = {}

end

-- dump the configure
function config.dump()
   
    -- dump
    table.dump(config.options(), "__%w*", "configure")
   
end

-- the configure has been changed for the given target?
function config.changed(targetname)

    -- get the target name
    targetname = targetname or "all"

    -- load configure from the file 
    local fileinfo = {}
    local filepath = config._file()
    if os.isfile(filepath) then

        -- load it 
        local results = io.load(filepath)
        if results then

            -- get the target configure first
            if targetname ~= "all" and results._TARGETS then
                for name, value in pairs(table.wrap(results._TARGETS[targetname])) do
                    fileinfo[name] = value
                end
            end

            -- merge the root configure 
            for name, value in pairs(results) do
                if fileinfo[name] == nil then
                    fileinfo[name] = value
                end
            end
        end
    end

    -- compare the current configure
    for name, value in pairs(config.options()) do

        -- changed?
        if fileinfo[name] ~= value then
            return true
        end
    end
end

-- return module
return config
