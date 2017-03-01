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

-- load the project configure
function config._load(targetname)

    -- check
    targetname = targetname or "all"

    -- load configure from the file first
    local filepath = config._file()
    if os.isfile(filepath) then

        -- load it 
        local results, errors = io.load(filepath)
        if not results then
            return nil, errors
        end

        -- load the target configure 
        if results._TARGETS then
            return table.wrap(results._TARGETS[targetname])
        end
    end

    -- empty
    return {}
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

-- get the buildir 
function config.buildir()
    
    -- get it 
    local buildir = config.get("buildir")
    if buildir then

        -- get the absolute path first
        if not path.is_absolute(buildir) then
            buildir = path.absolute(buildir, xmake._PROJECT_DIR)
        end

        -- adjust path for the current directory
        buildir = path.relative(buildir, os.curdir())
    end

    -- ok?
    return buildir
end

-- get the configure directory
function config.directory()

    -- get it
    return path.join(xmake._PROJECT_DIR, ".xmake")
end

-- load the project configure
function config.load(targetname)

    local results, errors = config._load(targetname)
    if not results then
        utils.error(errors)
        return true
    end

    -- merge the target configure first
    for name, value in pairs(results) do
        if config.get(name) == nil then
            config.set(name, value)
        end
    end

    -- ok
    return true
end

-- save the project configure
function config.save(targetname)

    -- check
    targetname = targetname or "all"

    -- load the previous results from configure
    local results = {}
    local filepath = config._file()
    if os.isfile(filepath) then
        results = io.load(filepath) or {}
    end

    -- the targets
    local targets = results._TARGETS or {}
    results._TARGETS = targets

    -- clear target first
    targets[targetname] = {}

    -- update target
    local target = targets[targetname]
    for name, value in pairs(config.options()) do
        target[name] = value
    end

    -- add version
    results.__version = xmake._VERSION_SHORT

    -- save it
    return io.save(config._file(), results) 
end

-- read value from the configure file directly
function config.read(name, targetname)

    -- load configs
    local configs = config._load(targetname)

    -- get it
    local value = nil
    if configs then
        value = configs[name]
        if type(value) == "string" and value == "auto" then
            value = nil
        end
    end

    -- ok?
    return value
end

-- init the config
function config.init()

    -- clear it
    config._CONFIGS = {}

end

-- dump the configure
function config.dump()
   
    -- dump
    if not option.get("quiet") then
        table.dump(config.options(), "__%w*", "configure")
    end
end

-- the configure has been changed for the given target?
function config.changed(targetname)

    -- check
    targetname = targetname or "all"

    -- load configure from the file 
    local fileinfo = {}
    local filepath = config._file()
    if os.isfile(filepath) then

        -- load it 
        local results = io.load(filepath)
        if results and results._TARGETS then
            for name, value in pairs(table.wrap(results._TARGETS[targetname])) do
                fileinfo[name] = value
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
