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
local io    = require("base/io")
local utils = require("base/utils")

-- save configs
function config._save()
    
    -- the options
    local options = xmake._OPTIONS
    assert(options)

    -- open the configure file
    local path = options.project .. "/xmake.conf"
    local file = io.open(path, "w")
    if not file then
        -- error
        utils.error("open %s failed!", path)
        return false
    end

    -- save configs to file
    if not io.save(file, xmake._CONFIGS, "return") then
        -- error 
        utils.error("save %s failed!", path)
        file:close()
        return false
    end

    -- close file
    file:close()
   
    -- ok
    return true
end
 
-- load configs
function config._load()

    -- the options
    local options = xmake._OPTIONS
    assert(options)

    -- the target
    local target = options.target or options._DEFAULTS.target
    assert(target)

    -- open the configure file
    local path = options.project .. "/xmake.conf"
    local file = loadfile(path)
    if file then
        -- execute it
        local ok, cfg = pcall(file)
        if not ok then
            -- error
            utils.error("load %s failed!", path)
            utils.error(cfg)
            return 
        end

        -- check
        assert(cfg and type(cfg) == "table")

        -- clear configs if the host environment has been changed
        if cfg[target] and cfg[target].host ~= xmake._HOST then
            cfg = {}
        end
        if cfg.all and cfg.all.host ~= xmake._HOST then
            cfg = {}
        end

        -- merges configs to xmake._CONFIGS
        xmake._CONFIGS = cfg
    end

    -- the configs
    xmake._CONFIGS = xmake._CONFIGS or {}
    local configs = xmake._CONFIGS

    -- init the configs for the target
    configs[target] = configs[target] or {}

    -- merge xmake._OPTIONS to xmake._CONFIGS[target]
    for k, v in pairs(options) do

        -- check
        assert(type(k) == "string")

        -- skip some options
        if not k:startswith("_") and k ~= "project" and k ~= "file" and k ~= "verbose" and k ~= "target" then

            -- save the option to the target
            configs[target][k] = v
        end
    end

    -- merge xmake._OPTIONS._DEFAULTS to xmake._CONFIGS[target]
    for k, v in pairs(options._DEFAULTS) do

        -- check
        assert(type(k) == "string")

        -- skip some options
        if k ~= "project" and k ~= "file" and k ~= "verbose" and k ~= "target" then

            -- save the default option to the target
            if not configs[target][k] then
                if v == "auto" then 
                    configs[target][k] = config._auto(k)
                else
                    configs[target][k] = v
                end
            end
        end
    end
end

-- auto configs
function config._auto(name)

    -- get platform or host
    if name == "plat" or name == "host" then
        return xmake._HOST
    -- get architecture
    elseif name == "arch" then
        return xmake._ARCH
    end

    -- unknown
    utils.error("unknown config: %s", name)
    return "unknown"
end

-- dump configs
function config._dump()
    
    -- dump
    if xmake._OPTIONS.verbose then
        utils.dump(xmake._CONFIGS, "configs = ")
    end
   
end
    
-- done the given config
function config.done()

    -- load configs
    config._load()

    -- dump configs
    config._dump()
 
    -- save configs
    if not config._save() then
        return false
    end

    -- ok
    print("configure ok!")
    return true
end

-- return module: config
return config
