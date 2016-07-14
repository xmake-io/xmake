--!The Make-like Build Utility based on Lua
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
    return path.join(global.directory(), "xmake.conf")
end

-- get the current given configure from  
function global.get(name)

    -- get configs
    local configs = global._CONFIGS or {}

    -- the value
    local value = configs[name]
    if type(value) == "string" and value == "auto" then
        value = nil
    end

    -- get it
    return value
end

-- set the current given configure  
function global.set(name, value)

    -- get configs
    local configs = global._CONFIGS or {}
    global._CONFIGS = configs

    -- set it 
    configs[name] = value

end

-- get all options
function global.options()
         
    -- remove values with "auto" and private item
    local configs = {}
    for name, value in pairs(table.wrap(global._CONFIGS)) do
        if not name:find("^_%u+") and name ~= "__version" and (type(value) ~= "string" or value ~= "auto") then
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
        local results, errors = io.load(filepath)

        -- error?
        if not results then
            utils.error(errors)
            return true
        end

        -- merge the configure 
        for name, value in pairs(results) do
            if global.get(name) == nil then
                global.set(name, value)
            end
        end
    end

    -- ok
    return true
end

-- save the global configure
function global.save()

    -- the options
    local options = global.options()
    assert(options)

    -- add version
    options.__version = xmake._VERSION_SHORT

    -- save it
    return io.save(global._file(), options) 
end

-- init the config
function global.init()

    -- clear it
    global._CONFIGS = {}

end

-- dump the configure
function global.dump()
   
    -- dump
    table.dump(global.options(), "__%w*", "configure")
   
end

-- return module
return global
