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
    local path = options.project .. "/.config.lua"
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
 
-- load configs to xmake._OPTIONS from the configure file
function config._load()

    -- the options
    local options = xmake._OPTIONS
    assert(options)

    -- the target
    local target = options.target or options._DEFAULTS.target
    assert(target)

    -- open the configure file
    local path = options.project .. "/.config.lua"
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
                configs[target][k] = v
            end
        end
    end
end

-- save config 
function config._save_option(file, option)
 
    -- check
    assert(file and option)
    
    -- save string
    if type(option) == "string" then  
        file:write(string.format("%q", option))  
    -- save boolean
    elseif type(option) == "boolean" then  
        file:write(tostring(option))  
    -- save number 
    elseif type(option) == "number" then  
        file:write(option)  
    -- save table
    elseif type(option) == "table" then  

        -- save head
        file:write("{\n")  

        -- save body
        local i = 0
        for k, v in pairs(option) do  

            -- skip --project and --file
            if type(k) == "string" and not k:startswith("_") and k ~= "project" and k ~= "file" and k ~= "verbose" then

                -- save separator
                file:write(utils.ifelse(i == 0, "    ", ",   "), k, " = ")  

                -- save this key: value
                if not config._save_option(file, v) then 
                    return false 
                end 

                -- save newline
                file:write("\n")
                i = i + 1
            end
        end  

        -- save tail
        file:write("}\n")  
    else  
        -- error
        utils.error("invalid option type: %s", type(option))  
        return false
    end  

    -- ok
    return true
end

-- dump configs
function config._dump()
    
    -- dump
    utils.dump(xmake._CONFIGS, "configs = ")
   
end
    
-- done the given config
function config.done()

    -- load configs
    config._load()

    -- TODO

    -- dump configs
    config._dump()
 
    -- save configs
    if not config._save() then
        return false
    end

    -- ok
    return true
end

-- return module: config
return config
