--!The Make-like Build Utility based on Lua
--
-- Licensed to the Apache Software Foundation (ASF) under one
-- or more contributor license agreements.  See the NOTICE file
-- distributed with this work for additional information
-- regarding copyright ownership.  The ASF licenses this file
-- to you under the Apache License, Version 2.0 (the
-- "License"); you may not use this file except in compliance
-- with the License.  You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- 
-- Copyright (C) 2015 - 2017, TBOOX Open Source Group.
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
    return path.translate("~/.xmake")
end

-- load the global configure
function global.load()

    -- load configure from the file first
    local ok = false
    local filepath = global._file()
    if os.isfile(filepath) then

        -- load configs
        local results, errors = io.load(filepath)

        -- error?
        if not results then
            utils.error(errors)
            return false
        end

        -- merge the configure 
        for name, value in pairs(results) do
            if global.get(name) == nil then
                global.set(name, value)
                ok = true
            end
        end
    end

    -- ok?
    return ok
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

-- dump the configure
function global.dump()
   
    -- dump
    if not option.get("quiet") then
        table.dump(global.options(), "__%w*", "configure")
    end
end

-- return module
return global
