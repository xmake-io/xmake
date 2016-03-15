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
-- @file        main.lua
--

-- imports
import("core.base.option")
import("core.project.config")
import("core.project.global")

-- filter option 
function _option_filter(name)
    return name and name ~= "target" and name ~= "file" and name ~= "project" and name ~= "verbose" and name ~= "clean"
end

-- main
function main()

    -- load global configure
    global.load()

    -- load project configure
    config.load(option.get("target"))

    -- clean the cached configure?
    if option.get("clean") then
        
        -- clean it
        config.clean()
    end

    -- override the configure for the current options
    for name, value in pairs(option.options()) do
        if _option_filter(name) then
            config.set(name, value)
        end
    end

    -- merge the global configure 
    for name, value in pairs(global.options()) do 
        if config.get(name) == nil then
            config.set(name, value)
        end
    end

    -- merge the default options 
    for name, value in pairs(option.defaults()) do
        if _option_filter(name) and config.get(name) == nil then
            config.set(name, value)
        end
    end

    -- probe the configure with value: "auto"
    config.probe()

    -- TODO

    -- dump it
    config.dump()

    -- trace
    print("configure ok!")
    
end
