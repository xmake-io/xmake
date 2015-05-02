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
-- @file        option.lua
--

-- define module: option
local option = {}

-- load modules
local utils = require("base/utils")

-- init _OPTIONS.metatable to always use lowercase keys
local _OPTIONS_metatable = 
{
    __index = function(table, key)
        -- make lowercase key
        if type(key) == "string" then
            key = key:lower()
        end
        return rawget(table, key)
    end
,   __newindex = function(table, key, value)
        -- make lowercase key
        if type(key) == "string" then
            key = key:lower()
        end
        rawset(table, key, value)
    end
}
xmake._OPTIONS = xmake._OPTIONS or {}
setmetatable(xmake._OPTIONS, _OPTIONS_metatable)

-- done the option
function option.done(argv, menu)

    -- check
    assert(argv and menu)

    -- parse _ARGV to _OPTIONS
    for i, arg in ipairs(argv) do

        -- parse key and value
        local key, value
        local i = arg:find("=", 1, true)

        -- key=value?
        if i then
            key = arg:sub(1, i - 1)
            value = arg:sub(i + 1)
        -- only key?
        else
            key = arg
            value = ""
        end

        -- -k?
        if key:startswith("-") then
            xmake._OPTIONS[key:sub(2)] = value
        -- --key=value?
        elseif key:startswith("--") then
           xmake. _OPTIONS[key:sub(3)] = value
        end
    end

    -- save menu
    option._MENU = menu

    -- print main menu
    option.print_main()

    -- print action menu: create
    option.print_action("create")
    option.print_action("config")
    option.print_action("install")
    option.print_action("clean")

    -- ok
    return true
end

-- print the main menu
function option.print_main()

    -- the menu
    local menu = option._MENU
    assert(menu)

    -- the main menu
    local main = menu.main
    assert(main)

    -- print title
    if menu.title then
        print(menu.title)
    end

    -- print copyright
    if menu.copyright then
        print(menu.copyright)
    end

    -- print usage
    if main.usage then
        print("")
        print("Usage: " .. main.usage)
    end

    -- print description
    if main.description then
        print("")
        print(main.description)
    end

    -- print actions
    if main.actions then

        -- print header
        print("")
        print("Actions: ")
        
        -- the padding spaces
        local padding = 32

        -- print actions
        for _, action in ipairs(main.actions) do

            -- the action menu
            local action_menu = menu[action]

            -- init the action info
            local action_info = "    " .. utils.ifelse(action_menu and action_menu.shortname, action_menu.shortname .. ", ", "   ")
            
            -- append the action
            action_info = action_info .. action

            if action_menu then
                -- append spaces
                for i = (#action_info), padding do
                    action_info = action_info .. " "
                end

                -- append the action description
                if action_menu.description then
                    action_info = action_info .. action_menu.description
                end
            end

            -- print action info
            print(action_info)
        end
    end

    -- print options
    if main.options then
        option.print_options(main.options)
    end
end  

-- print the action menu 
function option.print_action(action)

    -- no action? print main menu
    if not action then 
        option.print_main()
    end

    -- the menu
    local menu = option._MENU
    assert(menu)

    -- the action
    action = menu[action]
    assert(action)

    -- print usage
    if action.usage then
        print("Usage: " .. action.usage)
    end

    -- print description
    if action.description then
        print("")
        print(action.description)
    end

    -- print options
    if action.options then
        option.print_options(action.options)
    end
end  

-- print the options menu 
function option.print_options(options)

    -- check
    assert(options)

    -- print header
    print("")
    print("Options: ")
    
    -- the padding spaces
    local padding = 32

    -- print options
    for _, option in ipairs(options) do
        
        -- init the option info
        local option_info   = ""

        -- append the shortname
        local shortname = option[1];
        local name      = option[2];
        local mode      = option[3];
        if shortname then
            option_info = option_info .. "    -" .. shortname
            if mode == "kv" then
                option_info = option_info .. " " .. utils.ifelse(name, name:upper(), "XXX")
            end
        end

        -- append the name
        if name then
            option_info = option_info .. utils.ifelse(shortname, ", --", "        --") .. name
            if mode == "kv" then
                option_info = option_info .. "=" .. name:upper()
            end
        elseif mode == "v" then
            option_info = option_info .. "    ..."
        end

        -- append spaces
        for i = (#option_info), padding do
            option_info = option_info .. " "
        end

        -- append the option description
        local description = option[5];
        if description then
            option_info = option_info .. description
        end

        -- append the default value
        local default = option[4];
        if default then
            option_info = option_info .. " (default: " .. default .. ")"
        end

        -- print option info
        print(option_info)

        -- print more description if exists
        for i = 6, #option do
            if option[i] then

                -- make spaces 
                local spaces = ""
                for i = 0, padding do
                    spaces = spaces .. " "
                end

                -- print this description
                print(spaces .. option[i])
            end
        end
    end
end  

-- return module: option
return option
