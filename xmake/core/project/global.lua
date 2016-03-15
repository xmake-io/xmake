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
-- @file        global.lua
--

-- define module
local global = global or {}

-- load modules
local io            = require("base/io")
local os            = require("base/os")
local path          = require("base/path")
local utils         = require("base/utils")
local option        = require("base/option")

-- get the configure file
function global._file()
    
    -- get it
    return path.join(global.directory(), "/xmake.conf")
end

-- make configure
function global._make(configs)

    -- check
    assert(configs)
   
    -- make current configure
    local current = {}
    for k, v in pairs(configs) do 
        if type(k) == "string" and not k:find("^_%u+") then
            current[k] = v
        end
    end

    -- ok
    return current
end

-- get the given configure from the current 
function global.get(name)

    -- check
    assert(global._CURRENT)

    -- the value
    local value = global._CURRENT[name]
    if type(value) == "string" and value == "auto" then
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

-- clean the global configure 
function global.clean()

    -- check
    assert(global._CURRENT and global._CONFIGS)

    -- clean it
    global._CURRENT = {}
    global._CONFIGS = {}

    -- save it
    if os.isfile(global._file()) then
        local ok, errors = os.rm(global._file())
        if not ok then
            return false, errors
        end
    end

    -- ok
    return true
end

-- get all options
function global.options()
        
    -- get it
    return global._CURRENT
end

-- get the global configure directory
function global.directory()

    -- get it
    return path.translate("~/.xmake")
end

-- load the global configure
function global.load()

    -- load configure from the file first
    local filepath = global._file()
    if os.isfile(filepath) then

        -- load configs
        local configs, errors = io.load(filepath)

        -- error?
        if not configs and errors then
            utils.error(errors)
        end

        -- save configs
        global._CONFIGS = configs
    end

    -- init configs
    global._CONFIGS = global._CONFIGS or {}

    -- make the current configs
    global._CURRENT = global._make(global._CONFIGS)

end

-- save the global configure
function global.save()

    -- check
    assert(global._CONFIGS)
   
    -- remove values with "auto" from the configure
    local configs = {}
    for name, value in pairs(global._CONFIGS) do
        if type(value) ~= "string" or value ~= "auto" then
            configs[name] = value
        end
    end

    -- add version
    configs.__version = xmake._VERSION

    -- save it
    return io.save(global._file(), configs) 
end

-- dump the current configure
function global.dump()
    
    -- check
    assert(global._CURRENT)
 
    -- remove values with "auto" from the configure
    local configs = {}
    for name, value in pairs(global._CURRENT) do
        if type(value) ~= "string" or value ~= "auto" then
            configs[name] = value
        end
    end

    -- dump
    utils.dump(configs, "__%w*", "configure")
   
end

-- return module
return global
