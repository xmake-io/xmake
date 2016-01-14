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
local table = require("base/table")

-- save the option menu
function option._save_menu(menu)

    -- translate the action menus if exists function
    local submenus_all = {}
    for k, submenu in pairs(menu) do
        if type(submenu) == "function" then
            local _submenus = submenu()
            if _submenus then
                for k, m in pairs(_submenus) do
                    submenus_all[k] = m
                end
            end
        else
            submenus_all[k] = submenu
        end
    end
    table.copy2(menu, submenus_all)

    -- translate the actions of the main menu if exists function
    if menu.main and type(menu.main.actions) == "function" then
        menu.main.actions = menu.main.actions()
    end

    -- translate it if exists function in the option menu
    for _, submenu in pairs(menu) do

        -- exits options?
        if submenu.options then
            
            -- translate options
            local options_all = {}
            for _, option in ipairs(submenu.options) do

                -- this option is function? translate it
                if type(option) == "function" then
                    local _options = option()
                    if _options then
                        for _, o in ipairs(_options) do
                            table.insert(options_all, o)
                        end
                    end
                else
                    table.insert(options_all, option)
                end
            end

            -- update the options
            submenu.options = options_all
        end
    end

    -- save menu
    option._MENU = menu

end

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
    option._save_menu(menu)

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

            -- value is "true" or "false", translate it
            if type(value) == "string" then
                if value == "true" then value = true
                elseif value == "false" then value = false
                end
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

                -- the mode
                local mode = o[3]

                -- the name
                local name = o[2]

                -- check
                assert(o and ((mode ~= "v" and mode ~= "vs") or name))

                -- is value and with name?
                if mode == "v" and name and not xmake._OPTIONS[name] then
                    opt = o
                    break 
                -- is values and with name?
                elseif mode == "vs" and name then
                    opt = o
                    break
                end
            end

            -- ok? save this value with name opt[2]
            if opt then 

                -- the mode
                local mode = opt[3]

                -- the name
                local name = opt[2]

                -- save value
                if mode == "v" then
                    xmake._OPTIONS[name] = key
                elseif mode == "vs" then
                    -- the option
                    local o = xmake._OPTIONS[name]
                    if not o then
                        xmake._OPTIONS[name] = {}
                        o = xmake._OPTIONS[name]
                    end

                    -- append value
                    table.insert(o, key)
                end
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
        -- value with name?
        elseif o[3] == "v" and o[2] then
            -- save the default value 
            xmake._OPTIONS._DEFAULTS[o[2]] = o[4]    
        end
    end

    -- ok
    return true
end

-- find the value of a given name from the arguments
-- only for kv mode and need not check it using menu
--
function option.find(argv, name, shortname)

    -- check
    assert(argv and (name or shortname))

    -- find it
    local nextvalue = false
    for _, arg in ipairs(argv) do

        -- get this value
        if nextvalue then return arg end

        -- --name=value?
        if name and arg:startswith("--" .. name) then
                    
            -- get value
            local i = arg:find("=", 1, true)
            if i then return arg:sub(i + 1) end

        -- -shortname value?
        elseif shortname and arg:startswith("-" .. shortname) then
 
            -- get value
            nextvalue = true
        end

    end
end

-- get all default options from the given action
function option.defaults(action)

    -- make defaults
    local defaults = {}

    -- init the default value
    for _, o in ipairs(option._MENU[action or "main"].options) do

        -- key=value?
        if o[3] == "kv" then

            -- the key
            local key = o[2] or o[1]
            assert(key)

            -- save the default value 
            defaults[key] = o[4]    
        -- value with name?
        elseif o[3] == "v" and o[2] then
            -- save the default value 
            defaults[o[2]] = o[4]    
        end
    end

    -- ok?
    return defaults
end

-- print the menu 
function option.print_menu(action)

    -- no action? print main menu
    if not action then 
        option.print_main()
        return 
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
        print("")
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
            local action_info = "    "
            if action_menu and action_menu.shortname then
                action_info = action_info .. action_menu.shortname .. ", "
            else
                action_info = action_info .. "   "
            end
            
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
        local description = option[5]
        if description then
            option_info = option_info .. description
        end

        -- append the default value
        local default = option[4]
        if default then
            option_info = option_info .. " (default: " .. tostring(default) .. ")"
        end

        -- print option info
        print(option_info)

        -- print more description if exists
        for i = 6, 64 do

            -- the description, @note some option may be nil
            local description = option[i]
            if not description then break end

            -- is function? get results
            if type(description) == "function" then
                description = description()
            end

            -- the description is string?
            if type(description) == "string" then

                -- make spaces 
                local spaces = ""
                for i = 0, padding do
                    spaces = spaces .. " "
                end

                -- print this description
                print(spaces .. description)

            -- the description is table?
            elseif type(description) == "table" then

                -- print all descriptions
                for _, v in pairs(description) do

                    -- make spaces 
                    local spaces = ""
                    for i = 0, padding do
                        spaces = spaces .. " "
                    end

                    -- print this description
                    print(spaces .. v)
                end
            end
        end
    end
end  

-- return module: option
return option
