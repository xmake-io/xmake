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
-- @file        option.lua
--

-- define module: option
local option = option or {}

-- load modules
local table = require("base/table")

-- ifelse, a? b : c
function option._ifelse(a, b, c)
    if a then return b else return c end
end

-- translate the menu
function option._translate(menu)

    -- translate the menus if exists function
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

    -- save menu
    option._MENU = menu

end

-- get the task menu
function option._taskmenu(task)

    -- check
    assert(option._MENU)
   
    -- the current task
    task = task or option.taskname() or "main"

    -- get the task menu
    local taskmenu = option._MENU[task]
    if type(taskmenu) == "function" then

        -- load this task menu
        taskmenu = taskmenu()

        -- save this task menu
        option._MENU[task] = taskmenu
    end

    -- get it
    return taskmenu
end

-- get the top context
function option._context()

    -- the contexts
    local contexts = option._CONTEXTS
    assert(contexts)

    -- get it
    return contexts[#contexts]
end

-- save context
function option.save(taskname)

    -- init contexts
    option._CONTEXTS = option._CONTEXTS or {}

    -- new a context
    local context = {options = {}, defaults = {}, taskname = taskname}

    -- push this new context to the top stack
    table.insert(option._CONTEXTS, context)

    -- ok
    return context
end

-- restore context
function option.restore()

    -- pop it
    if option._CONTEXTS then
        table.remove(option._CONTEXTS)
    end
end

-- init the option
function option.init(argv, menu)

    -- check
    assert(argv and menu)

    -- translate menu
    option._translate(menu)

    -- the main menu
    local main = option._taskmenu("main")
    assert(main)

    -- new top context
    local context = option.save()
    assert(context)

    -- parse _ARGV 
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
            option.show_menu(context.taskname)

            -- failed
            return false
        end

        -- --key=value or -k value or -k?
        if prefix ~= 0 then

            -- find this option
            local opt = nil
            for _, o in ipairs(option._taskmenu().options) do

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
                option.show_menu(context.taskname)

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
                    print("invalid option: " .. option._ifelse(idx, arg, key))

                    -- print menu
                    option.show_menu(context.taskname)

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
                option.show_menu(context.taskname)

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
            context.options[option._ifelse(prefix == 1 and opt[2], opt[2], key)] = value

        -- task?
        elseif idx == 1 then

            -- find the current task
            for taskname, taskinfo in pairs(main.tasks) do

                -- ok?
                if taskname == key or taskinfo.shortname == key then
                    -- save this task
                    context.taskname = taskname 
                    break 
                end
            end

            -- not found?
            if not context.taskname or not menu[context.taskname] then

                -- invalid task
                print("invalid task: " .. key)

                -- print the main menu
                option.show_main()

                -- failed
                return false
                
            end

        -- value?
        else 
            
            -- find a value option with name
            local opt = nil
            for _, o in ipairs(option._taskmenu().options) do

                -- the mode
                local mode = o[3]

                -- the name
                local name = o[2]

                -- check
                assert(o and ((mode ~= "v" and mode ~= "vs") or name))

                -- is value and with name?
                if mode == "v" and name and not context.options[name] then
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
                    context.options[name] = key
                elseif mode == "vs" then
                    -- the option
                    local o = context.options[name]
                    if not o then
                        context.options[name] = {}
                        o = context.options[name]
                    end

                    -- append value
                    table.insert(o, key)
                end
            else
                -- invalid option
                print("invalid option: " .. arg)
            
                -- print menu
                option.show_menu(context.taskname)

                -- failed
                return false
            end

        end
    end

    -- init the default value
    for _, o in ipairs(option._taskmenu().options) do

        -- key=value?
        if o[3] == "kv" then

            -- the key
            local key = o[2] or o[1]
            assert(key)

            -- save the default value 
            context.defaults[key] = o[4]    
        -- value with name?
        elseif o[3] == "v" and o[2] then
            -- save the default value 
            context.defaults[o[2]] = o[4]    
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

-- get the current task name
function option.taskname()

    -- get it
    return option._context().taskname
end

-- get the given option value for the current task
function option.get(name)

    -- check
    assert(name)

    -- the options
    local options = option.options()
    assert(options)

    -- get it
    return options[name] or option.default(name)
end

-- set the given option for the current task
function option.set(name, value)

    -- check
    assert(name)

    -- cannot be the first context for menu
    assert(#option._CONTEXTS > 1)

    -- the options
    local options = option.options()
    assert(options)

    -- set it
    options[name] = value
end

-- get the given default option value for the current task
function option.default(name)

    -- check
    assert(name)

    -- the defaults
    local defaults = option.defaults()
    assert(defaults)

    -- get it
    return defaults[name]
end

-- get the current options
function option.options()

    -- get it
    return option._context().options
end

-- get all default options for the current or given task
function option.defaults(task)

    -- get the default options for the current task
    if task == nil then
        return option._context().defaults
    end

    -- get the default options for the given task
    local defaults = {}
    for _, o in ipairs(option._taskmenu(task).options) do

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

-- show the menu 
function option.show_menu(task)

    -- no task? print main menu
    if not task then 
        option.show_main()
        return 
    end

    -- the menu
    local menu = option._MENU
    assert(menu)

    -- the task menu
    local taskmenu = option._taskmenu(task)
    assert(taskmenu)

    -- print title
    if menu.title then
        print(menu.title)
    end

    -- print copyright
    if menu.copyright then
        print(menu.copyright)
    end

    -- print usage
    if taskmenu.usage then
        print("")
        print("Usage: " .. taskmenu.usage)
    end

    -- print description
    if taskmenu.description then
        print("")
        print(taskmenu.description)
    end

    -- print options
    if taskmenu.options then
        option.show_options(taskmenu.options)
    end
end  

-- show the main menu
function option.show_main()

    -- the menu
    local menu = option._MENU
    assert(menu)

    -- the main menu
    local main = option._taskmenu("main")
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

    -- print tasks
    if main.tasks then

        -- make task categories
        local categories = {}
        for taskname, taskinfo in pairs(main.tasks) do

            -- the category name
            local categoryname = taskinfo.category or "task"
            if categoryname == "main" then
                categoryname = "action"
            end

            -- the category task
            local categorytask = categories[categoryname] or {}
            categories[categoryname] = categorytask

            -- add task to the category
            categorytask[taskname] = taskinfo
        end

        -- sort categories
        local categories_sorted = {}
        for categoryname, categorytask in pairs(categories) do
            if categoryname == "action" then
                table.insert(categories_sorted, 1, {categoryname, categorytask})
            else
                table.insert(categories_sorted, {categoryname, categorytask})
            end
        end

        -- dump tasks by categories
        for _, categoryinfo in ipairs(categories_sorted) do

            -- the category name and task
            local categoryname = categoryinfo[1]
            local categorytask = categoryinfo[2]
            assert(categoryname and categorytask)

            -- print category name
            print("")
            print(string.format("%s%ss: ", string.sub(categoryname, 1, 1):upper(), string.sub(categoryname, 2)))
            
            -- the padding spaces
            local padding = 42

            -- print tasks
            for taskname, taskinfo in pairs(categorytask) do

                -- init the task line
                local taskline = "    "
                if taskinfo.shortname then
                    taskline = taskline .. taskinfo.shortname .. ", "
                else
                    taskline = taskline .. "   "
                end
                
                -- append the task name
                taskline = taskline .. taskname

                -- append spaces
                for i = (#taskline), padding do
                    taskline = taskline .. " "
                end

                -- append the task description
                if taskinfo.description then
                    taskline = taskline .. taskinfo.description
                end

                -- print task line
                print(taskline)
            end
        end
    end

    -- print options
    if main.options then
        option.show_options(main.options)
    end
end  

-- show the options menu 
function option.show_options(options)

    -- check
    assert(options)

    -- print header
    print("")
    print("Options: ")
    
    -- the padding spaces
    local padding = 42

    -- print options
    for _, opt in ipairs(options) do
        
        -- init the option info
        local option_info   = ""

        -- append the shortname
        local shortname = opt[1];
        local name      = opt[2];
        local mode      = opt[3];
        if shortname then
            option_info = option_info .. "    -" .. shortname
            if mode == "kv" then
                option_info = option_info .. " " .. option._ifelse(name, name:upper(), "XXX")
            end
        end

        -- append the name
        if name then
            if mode == "v" then
                option_info = option_info .. "    " .. name
            else
                option_info = option_info .. option._ifelse(shortname, ", --", "        --") .. name
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
        local description = opt[5]
        if description then
            option_info = option_info .. description
        end

        -- append the default value
        local default = opt[4]
        if default then
            option_info = option_info .. " (default: " .. tostring(default) .. ")"
        end

        -- print option info
        print(option_info)

        -- print more description if exists
        for i = 6, 64 do

            -- the description, @note some option may be nil
            local description = opt[i]
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
