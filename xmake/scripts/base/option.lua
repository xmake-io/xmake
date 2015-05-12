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
local option = option or {}

-- load modules
local utils = require("base/utils")

-- init the option
function option.init(argv, menu)

    -- check
    assert(argv and menu)

    -- the main menu
    local main = menu.main
    assert(main)

    -- init _OPTIONS
    xmake._OPTIONS = {}
    xmake._OPTIONS._DEFAULTS = {}

    -- save menu
    option._MENU = menu

    -- parse _ARGV to _OPTIONS
    local _iter, _s, _k = ipairs(argv)
    while true do

        -- the idx and arg
        local idx, arg = _iter(_s, _k)

        -- end?
        _k = idx
        if idx == nil then break end

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
            value = true
        end

        -- --key?
        local prefix = 0
        if key:startswith("--") then
            key = key:sub(3)
            prefix = 2
        -- -k?
        elseif key:startswith("-") then
            key = key:sub(2)
            prefix = 1
        end

        -- check key
        if prefix and #key == 0 then

            -- invalid option
            print("invalid option: " .. arg)

            -- print menu
            option.print_menu(xmake._OPTIONS._ACTION)

            -- failed
            return false
        end

        -- --key=value or -k value or -k?
        if prefix ~= 0 then

            -- find this option
            local opt = nil
            for _, o in ipairs(menu[xmake._OPTIONS._ACTION or "main"].options) do

                -- check
                assert(o)

                -- --key?
                if prefix == 2 and key == o[2] then
                    opt = o
                    break 
                -- k?
                elseif prefix == 1 and key == o[1] then
                    opt = o
                    break
                end
            end

            -- not found?
            if not opt then

                -- invalid option
                print("invalid option: " .. arg)

                -- print menu
                option.print_menu(xmake._OPTIONS._ACTION)

                -- failed
                return false
            end

            -- -k value? continue to get the value
            if prefix == 1 and opt[3] == "kv" then

                -- get the next idx and arg
                idx, arg = _iter(_s, _k)

                -- exists value?
                _k = idx
                if idx == nil or arg:startswith("-") then 

                    -- invalid option
                    print("invalid option: " .. utils.ifelse(idx, arg, key))

                    -- print menu
                    option.print_menu(xmake._OPTIONS._ACTION)

                    -- failed
                    return false
                end

                -- get value
                value = arg
            end

            -- check mode
            if (opt[3] == "k" and type(value) ~= "boolean") or (opt[3] == "kv" and type(value) ~= "string") then

                -- invalid option
                print("invalid option: " .. arg)
            
                -- print menu
                option.print_menu(xmake._OPTIONS._ACTION)

                -- failed
                return false
            end

            -- save option
            xmake._OPTIONS[utils.ifelse(prefix == 1 and opt[2], opt[2], key)] = value

        -- action?
        elseif idx == 1 then

            -- find this action
            for _, action in ipairs(main.actions) do

                -- check
                assert(menu[action])

                -- ok?
                if action == key or menu[action].shortname == key then
                    -- save this action
                    xmake._OPTIONS._ACTION = action 
                    break 
                end
            end

            -- not found?
            if not xmake._OPTIONS._ACTION or not menu[xmake._OPTIONS._ACTION] then

                -- invalid action
                print("invalid action: " .. key)

                -- print the main menu
                option.print_main()

                -- failed
                return false
                
            end

        -- value?
        else 
            
            -- find a value option with name
            local opt = nil
            for _, o in ipairs(menu[xmake._OPTIONS._ACTION or "main"].options) do

                -- check
                assert(o and (o[3] ~= "v" or o[2]))

                -- is value and with name?
                if o[3] == "v" and o[2] and not xmake._OPTIONS[o[2]] then
                    opt = o
                    break 
                end
            end

            -- ok? save this value with name opt[2]
            if opt then 
                xmake._OPTIONS[opt[2]] = key
            else
                -- invalid option
                print("invalid option: " .. arg)
            
                -- print menu
                option.print_menu(xmake._OPTIONS._ACTION)

                -- failed
                return false
            end

        end
    end

    -- init the default value
    for _, o in ipairs(menu[xmake._OPTIONS._ACTION or "main"].options) do

        -- key=value?
        if o[3] == "kv" then

            -- the key
            local key = o[2] or o[1]
            assert(key)

            -- save the default value 
            xmake._OPTIONS._DEFAULTS[key] = o[4]    
        end
    end

    -- dump options
--    for a, b in pairs(xmake._OPTIONS) do
--        print(a, b)
--    end

    -- ok
    return true
end

-- print the menu 
function option.print_menu(action)

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

    -- print title
    if menu.title then
        print(menu.title)
    end

    -- print copyright
    if menu.copyright then
        print(menu.copyright)
    end

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
        local padding = 42

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

-- print the options menu 
function option.print_options(options)

    -- check
    assert(options)

    -- print header
    print("")
    print("Options: ")
    
    -- the padding spaces
    local padding = 42

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
            if mode == "v" then
                option_info = option_info .. "    " .. name
            else
                option_info = option_info .. utils.ifelse(shortname, ", --", "        --") .. name
            end
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
