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
local utils         = require("base/utils")
local option        = require("base/option")
local global        = require("project/global")

-- get the configure file
function config._file()
    
    -- get it
    return path.join(config.directory(), "/xmake.conf")
end

-- get the target scope
function config._target()
 
    -- check
    local configs = config._CONFIGS
    if not configs then
        return 
    end
  
    -- the target name
    local targetname = config._TARGETNAME
    assert(targetname)

    -- for all targets?
    if targetname == "all" then
        return configs
    elseif configs._TARGETS then
        -- get it
        return configs._TARGETS[targetname]
    end
end

-- get the current given configure
function config.get(name)

    -- get the target
    local target = config._target()
    if not target then
        return 
    end

    -- the value
    local value = target[name]
    if type(value) == "string" and value == "auto" then
        value = nil
    end

    -- get it from the root scope if not found
    if value == nil then
        value = config._CONFIGS[name]
        if type(value) == "string" and value == "auto" then
            value = nil
        end
    end

    -- get it
    return value
end

-- set the given configure to the current 
function config.set(name, value)

    -- check
    assert(name)

    -- get the current target
    local target = config._target()
    assert(target)

    -- set it 
    target[name] = value
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

-- clean the project configure 
function config.clean()

    -- check
    assert(config._CONFIGS)

    -- clean it
    config._CONFIGS = {}

    -- save it
    if os.isfile(config._file()) then
        local ok, errors = os.rm(config._file())
        if not ok then
            return false, errors
        end
    end

    -- ok
    return true
end

-- get the configure directory
function config.directory()

    -- get it
    return path.join(xmake._PROJECT_DIR, ".xmake")
end

-- TODO: reconfig, rebuild
-- load the project configure
function config.load(targetname)

    -- check
    if not targetname then
        return false, "no target name!"
    end

    -- load configure from the file first
    local filepath = config._file()
    if os.isfile(filepath) then

        -- load configs
        local configs, errors = io.load(filepath)

        -- error?
        if not configs and errors then
            utils.error(errors)
        end

        -- save configs
        config._CONFIGS = configs
    end

    -- init configs
    config._CONFIGS = config._CONFIGS or {}
    local configs = config._CONFIGS

    -- init targets
    configs._TARGETS = configs._TARGETS or {}
    if targetname ~= "all" then
        configs._TARGETS[targetname] = configs._TARGETS[targetname] or {}
    end

    -- save the target name
    config._TARGETNAME = targetname

    -- ok
    return true
end

-- save the project configure
function config.save()

    -- the options
    local options = config.options()
    assert(options)

    -- add version
    options.__version = xmake._VERSION

    -- save it
    return io.save(config._file(), options) 
end

-- dump the configure
function config.dump()
   
    -- dump
    table.dump(config.options(), "__%w*", "configure")
   
end

-- return module
return config
