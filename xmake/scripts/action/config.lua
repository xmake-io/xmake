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
local utils = require("base/utils")

-- save option to the file
function config._save_option(file, option)
 
    -- check
    assert(file and option)

    -- save number
    if type(option) == "number" then  
        file:write(option)  
    -- save string
    elseif type(option) == "string" then  
        file:write(string.format("%q", option))  
    -- save table
    elseif type(option) == "table" then  

        -- save head
        file:write("{\n")  

        -- save body
        local i = 0
        for k, v in pairs(option) do  

            -- skip --project and --file
            if k ~= "project" and k ~= "file" and k ~= "verbose" and k ~= "_ACTION" then

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

-- save xmake._OPTIONS to the configure file
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

    -- save return to file
    file:write("return \n")

    -- save options to file
    if not config._save_option(file, options) then
        -- error
        utils.error("save %s failed!", path)
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

    -- open the configure file
    local path = options.project .. "/.config.lua"
    local file = loadfile(path)
    if file then
        -- execute it
        local ok, configs = pcall(file)
        if not ok then
            -- error
            utils.error("load %s failed!", path)
            utils.error(configs)
            return 
        end

        -- check
        assert(configs and type(configs) == "table")

        -- ok? merge xmake._OPTIONS to configs
        for k, v in pairs(xmake._OPTIONS) do
            if type(k) == "string" then
                configs[k] = v
            else
                -- error
                utils.error("invalid option type: %s", type(k))
                return 
            end
        end

        -- update configs to xmake._OPTIONS
        xmake._OPTIONS = configs
    else
        -- error
        utils.error("%s not found!", path)
    end
end
    
-- done the given config
function config.done()

    -- attempt to load configs to xmake._OPTIONS from the configure file
    config._load()

    -- save options to the configure file
    if not config._save() then
        return false
    end

    -- dump
    for k, v in pairs(xmake._OPTIONS) do
        utils.printf("%s = %s", k, v)
    end
    
    -- ok
    return true
end

-- return module: config
return config
