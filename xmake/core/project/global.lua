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

-- get the current given configure from  
function global.get(name)

    -- check
    assert(name and global._CONFIGS)

    -- the value
    local value = global._CONFIGS[name]
    if type(value) == "string" and value == "auto" then
        value = nil
    end

    -- get it
    return value
end

-- set the current given configure  
function global.set(name, value)

    -- check
    assert(global._CONFIGS and name)

    -- set it 
    global._CONFIGS[name] = value

end

-- clean the global configure 
function global.clean()

    -- check
    assert(global._CONFIGS)

    -- clean it
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
         
    -- check
    assert(global._CONFIGS)
         
    -- remove values with "auto" and private item
    local configs = {}
    for name, value in pairs(global._CONFIGS) do
        if not name:find("^_%u+") and (type(value) ~= "string" or value ~= "auto") then
            configs[name] = value
        end
    end

    -- get it
    return configs
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

    -- ok
    return true
end

-- save the global configure
function global.save()

    -- the options
    local options = global.options()
    assert(options)

    -- add version
    options.__version = xmake._VERSION

    -- save it
    return io.save(global._file(), options) 
end

-- dump the configure
function global.dump()
   
    -- dump
    table.dump(global.options(), "__%w*", "configure")
   
end

-- return module
return global
