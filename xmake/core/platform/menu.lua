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
-- @file        menu.lua
--

-- define module
local menu          = menu or {}

-- load modules
local os            = require("base/os")
local path          = require("base/path")
local utils         = require("base/utils")
local table         = require("base/table")
local platform      = require("platform/platform")

-- get the option menu for action: xmake config or global
function menu.options(action)
    
    -- check
    assert(action)

    -- get all platforms
    local plats = platform.plats()
    assert(plats)

    -- load and merge all platform options
    local exist     = {}
    local results   = {}
    for _, plat in ipairs(plats) do

        -- load platform
        local instance, errors = platform.load(plat)
        if not instance then
            return nil, errors
        end

        -- get menu
        local menu = instance:menu()
        if menu then

            -- get the options for this action
            local options = menu[action]
            if options then

                -- exists options?
                local exists = false
                for _, option in ipairs(options) do
                    local name = option[2]
                    if name and not exist[name] then
                        exists = true
                        break
                    end
                end

                -- merge it and remove repeat if exists options
                if exists then

                    -- get the platform option
                    for _, option in ipairs(options) do

                        -- merge it and remove repeat 
                        local name = option[2]
                        if name then
                            if not exist[name] then
                                table.insert(results, option)
                                exist[name] = true
                            end
                        else
                            table.insert(results, option)
                        end
                    end
                end
            end
        end
    end

    -- ok?
    return results
end

-- return module
return menu
