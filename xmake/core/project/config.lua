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

-- make configure 
function config._make(configs)

    -- init current target configure
    local current = {}

    --[[
    -- get configs from the default configure 
    if configs._DEFAULTS then
        for k, v in pairs(configs._DEFAULTS) do 
            if type(v) ~= "string" or v ~= "auto" then current[k] = v end
        end
    end
    ]]

    -- make current configure from the global configure 
    for k, v in pairs(global.options()) do 
        current[k] = v
    end

    -- make current configure from the project configure
    for k, v in pairs(configs) do 
        if type(k) == "string" and not k:find("^_%u+") then
            current[k] = v
        end
    end

    --[[
    -- get configs from the current target 
    if configs._TARGETS and current.target ~= "all" then

        -- get the target config
        local target_config = configs._TARGETS[current.target]
        if target_config then

            -- merge it
            for k, v in pairs(target_config) do
                current[k] = v
            end
        end
    end]]

    -- ok
    return current
end

-- clean the project configure 
function config.clean()

    -- check
    assert(config._CURRENT and config._CONFIGS)

    -- clean it
    config._CURRENT = {}
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

-- TODO: reconfig, rebuild, defaults, targets
-- load the project configure
function config.load()

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

    -- make the current configs
    config._CURRENT = config._make(global._CONFIGS)

end

-- return module
return config
