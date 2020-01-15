--!A cross-platform build utility based on Lua
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- 
-- Copyright (C) 2015-2020, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        option.lua
--

-- define module: option
local option = option or {}

-- load modules
local cli       = require("base/cli")
local table     = require("base/table")
local colors    = require("base/colors")

local dump    = require("base/dump")

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
            local ok, _submenus_or_errors = pcall(submenu)
            if ok and _submenus_or_errors then
                for k, m in pairs(_submenus_or_errors) do
                    submenus_all[k] = m
                end
            else 
                return false, (_submenus_or_errors or "translate option menu failed!")
            end
        else
            submenus_all[k] = submenu
        end
    end
    table.copy2(menu, submenus_all)

    -- save menu
    option._MENU = menu

    -- ok
    return true
end

-- get the top context
function option._context()

    -- the contexts
    local contexts = option._CONTEXTS
    if contexts then
        return contexts[#contexts]
    end
end

-- get line length
function option._get_linelen(st)
    local poss = st:reverse():find("\n")
    if not poss then return (#st) end
    local start_pos, _ = poss
    return start_pos - 1
end

-- get last space
function option._get_lastspace(st)
    local poss = st:reverse():find("[%s-]")
    if not poss then return (#st) end
    local start_pos, _ = poss
    return (#st) - start_pos + 1
end

-- append spaces in width
function option._inwidth_append(dst, st, padding, width, remain_width)
    
    if padding >= width then
        return dst .. st
    end

    local white_padding = string.rep(" ", padding)
    if remain_width == nil then 
        -- TODO because of colored string, it's wrong sometimes
        remain_width = width - option._get_linelen(dst) 
    end

    if remain_width <= 0 then
        return option._inwidth_append(dst .. "\n" .. white_padding, st, padding, width, width - padding)
    end
    
    if (#st) <= remain_width then
        return dst .. st
    end
    
    local lastspace = option._get_lastspace(st:sub(1, remain_width))
    if lastspace + 1 > (#st) then
        return dst .. st
    else
        return option._inwidth_append(dst .. st:sub(1, lastspace) .. "\n" .. white_padding, st:sub(lastspace + 1):ltrim(), padding, width, width - padding)
    end
end

-- save context
function option.save(taskname)

    -- init contexts
    option._CONTEXTS = option._CONTEXTS or {}

    -- new a context
    local context = {options = {}, defaults = {}, taskname = taskname}

    -- init defaults
    if taskname then
        context.defaults = option.defaults(taskname) or context.defaults
    end

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

-- the command line
function option.cmdline()

    -- make command 
    local line = "xmake"
    local argv = xmake._ARGV
    for _, arg in ipairs(argv) do
        if arg:find("%s") then
            arg = "\"" .. arg .. "\""
        end
        line = line .. " " .. arg
    end

    -- ok?
    return line
end

-- init the option
function option.init(menu)

    -- check
    assert(menu)

    -- translate menu
    local ok, errors = option._translate(menu)
    if not ok then
        return false, errors
    end

    -- the main menu
    local main = option.taskmenu("main")
    assert(main)

    -- new top context
    local context = option.save()
    assert(context)

    -- check command
    if xmake._COMMAND then

        -- find the current task
        for taskname, taskinfo in pairs(main.tasks) do

            -- ok?
            if taskname == xmake._COMMAND or taskinfo.shortname == xmake._COMMAND then
                -- save this task
                context.taskname = taskname
                break
            end
        end

        -- not found?
        if not context.taskname or not menu[context.taskname] then

            -- print the main menu
            option.show_main()

            -- invalid task
            return false, "invalid task: " .. xmake._COMMAND
        end
    end

    local options = table.wrap(option.taskmenu().options)

    -- parse remain parts
    local results, err = option.parse(xmake._COMMAND_ARGV, options, { populate_defaults = false })
    if not results then
        option.show_menu(context.taskname)
        return false, err
    end

    -- finish parsing
    context.options = results

    -- init the default value
    option.populate_defaults(options, context.defaults)

    -- ok
    return true
end

-- parse arguments with the given options
function option.parse(argv, options, opt)

    -- check
    assert(argv and options)
    opt = opt or { populate_defaults = true }

    -- parse arguments
    local results   = {}
    local flags = {}
    for _, o in ipairs(options) do

        -- the mode
        local mode = o[3]

        -- the name
        local name = o[2]

        -- check
        assert(o and ((mode ~= "v" and mode ~= "vs") or name))

        -- fill short flags
        if o[3] == 'k' and o[1] then
            table.insert(flags, o[1])
        end
    end

    -- run parser
    local pargs = cli.parsev(argv, flags)

    -- save parse results
    for i, arg in ipairs(pargs) do
        if arg.type == "option" or arg.type == "flag" then

            -- find option or flag
            local name_idx = arg.short and 1 or 2
            local match_opt = nil
            for _, o in pairs(options) do
                local name = o[name_idx]
                if name == arg.key then
                    match_opt = o
                    break
                end
            end

            -- save option
            if match_opt and ((arg.type == "option" and match_opt[3] ~= "k") or (arg.type == "flag" and match_opt[3] == "k")) then
                results[match_opt[2] or match_opt[1]] = option.boolean(arg.value)
            else
                if opt.allow_unknown then
                    results[arg.key] = option.boolean(arg.value)
                else
                    return nil, string.format("Invalid %s: %s", arg.type, arg)
                end
            end

        elseif arg.type == "arg" then

            -- find a value option with name
            local match_opt = nil
            for _, o in ipairs(options) do

                -- the mode
                local mode = o[3]

                -- the name
                local name = o[2]

                -- is value and with name?
                if mode == "v" and name and not results[name] then
                    match_opt = o
                    break
                -- is values and with name?
                elseif mode == "vs" and name then
                    match_opt = o
                    break
                end
            end

            -- ok? save this value with name opt[2]
            if match_opt then

                -- the mode
                local mode = match_opt[3]

                -- the name
                local name = match_opt[2]

                -- save value
                if mode == "v" then
                    results[name] = arg.value
                elseif mode == "vs" then
                    -- the option
                    local o = results[name]
                    if not o then
                        results[name] = {}
                        o = results[name]
                    end

                    -- append value
                    table.insert(o, arg.value)
                end
            else

                -- failed
                if opt.allow_unknown then
                    if arg.key then
                        results[arg.key] = arg.value
                    else
                        -- the option
                        local o = results["$ARGS"]
                        if not o then
                            results["$ARGS"] = {}
                            o = results["$ARGS"]
                        end

                        -- append value
                        table.insert(o, arg.value)
                    end
                else
                    return nil, string.format("Invalid %s: %s", arg.type, arg)
                end
                return nil, "invalid argument: " .. arg.value
            end
        end
    end

    -- init the default value
    if opt.populate_defaults then
        option.populate_defaults(options, results)
    end

    -- ok
    return results
end

-- fill defined with option's default value, in place
function option.populate_defaults(options, defined)

    -- check
    assert(options and defined)

    -- populate the default value
    for _, o in ipairs(options) do

        -- the long name
        local longname = o[2]

        -- key=value?
        if o[3] == "kv" then

            local shortname = o[1]
            -- the key
            local key = longname or shortname
            assert(key)

            -- move value to key if needed
            if shortname and defined[shortname] ~= nil then
                defined[key], defined[shortname] = defined[shortname], nil
            end

            -- save the default value
            if defined[key] == nil then
                defined[key] = o[4]
            end

        -- value with name?
        elseif o[3] == "v" and longname then

            -- save the default value
            if defined[longname] == nil then
                defined[longname] = o[4]
            end
        end
    end
end


-- get the current task name
function option.taskname()
    return option._context().taskname
end

-- get the task menu
function option.taskmenu(task)

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

-- get the given option value for the current task
function option.get(name)

    -- check
    assert(name)

    -- the options
    local options = option.options()
    if options then
        local value = options[name]
        if value == nil then
            value = option.default(name)
        end
        return value
    end
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

-- get the boolean value
function option.boolean(value)
    if type(value) == "string" then
        local v = value:lower()
        if v == "true" or v == "yes" or v == "y" then value = true
        elseif v == "false" or v == "no" or v == "n" then value = false
        end
    end
    return value
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
    local context = option._context()
    if context then
        return context.options
    end
end

-- get all default options for the current or given task
function option.defaults(task)

    -- get the default options for the current task
    if task == nil then
        return option._context().defaults
    end

    -- the task menu
    local taskmenu = option.taskmenu(task)

    -- get the default options for the given task
    local defaults = {}
    option.populate_defaults(taskmenu.options, defaults)
    return defaults
end

-- show update tips
function option.show_update_tips()

    -- show latest version 
    local versionfile = path.join(os.tmpdir(), "latest_version")
    if os.isfile(versionfile) then
        local versioninfo = io.load(versionfile)
        if versioninfo and versioninfo.version and semver.compare(versioninfo.version, xmake._VERSION_SHORT) > 0 then
            local updatetips = nil
            if os.host() == "windows" then
                updatetips = string.format([[
   ==========================================================================
  | ${bright yellow}A new version of xmake is available!${clear}                                     |
  |                                                                          |
  | To update to the latest version ${bright}%s${clear}, run "xmake update".              |
   ==========================================================================
]], versioninfo.version)
            else
                updatetips = string.format([[
  ╔════════════════════════════════════════════════════════════════════════════╗
  ║ ${bright yellow}A new version of xmake is available!${clear}                                       ║
  ║                                                                            ║
  ║ To update to the latest version ${bright}%s${clear}, run "xmake update".                ║
  ╚════════════════════════════════════════════════════════════════════════════╝
]], versioninfo.version)
            end
            io.print(colors.translate(updatetips))
        end
    end
end

-- show logo
function option.show_logo()

    -- define logo
    local logo = [[
                         _        
    __  ___ __  __  __ _| | ______ 
    \ \/ / |  \/  |/ _  | |/ / __ \
     >  <  | \__/ | /_| |   <  ___/
    /_/\_\_|_|  |_|\__ \|_|\_\____| 

                         by ruki, tboox.org
    ]]

    -- make rainbow for logo
    if colors.truecolor() or colors.color256() then
        local lines = {} 
        local seed  = 236
        for _, line in ipairs(logo:split("\n")) do
            local i = 0
            local line2 = ""
            line:gsub(".", function (c)
                local code = colors.truecolor() and colors.rainbow24(i, seed) or colors.rainbow256(i, seed)
                line2 = string.format("%s${%s}%s", line2, code, c)
                i = i + 1
            end)
            table.insert(lines, line2)
        end
        logo = table.concat(lines, "\n")
    end

    -- show logo
    io.print(colors.translate(logo))

    -- define footer
    local footer = [[
    ${point_right}  ${bright}Manual${clear}: ${underline}https://xmake.io/#/getting_started${clear}
    ${pray}  ${bright}Donate${clear}: ${underline}https://xmake.io/#/sponsor${clear}
    ]]

    -- show footer
    io.print(colors.translate(footer))

    -- show update tips
    option.show_update_tips()
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
    local taskmenu = option.taskmenu(task)
    assert(taskmenu)

    -- print title
    if menu.title then
        io.print(colors.translate(menu.title))
    end

    -- print copyright
    if menu.copyright then
        io.print(colors.translate(menu.copyright))
    end

    -- show logo
    option.show_logo()

    -- print usage
    if taskmenu.usage then
        io.print("")
        io.print(colors.translate("${bright}Usage: $${default color.menu.usage}" .. taskmenu.usage .. "${clear}"))
    end

    -- print description
    if taskmenu.description then
        io.print("")
        io.print(taskmenu.description)
    end

    -- print options
    if taskmenu.options then
        option.show_options(taskmenu.options, task)
    end
end  

-- show the main menu
function option.show_main()

    -- the menu
    local menu = option._MENU
    assert(menu)

    -- the main menu
    local main = option.taskmenu("main")
    assert(main)

    -- print title
    if menu.title then
        io.print(colors.translate(menu.title))
    end

    -- print copyright
    if menu.copyright then
        io.print(colors.translate(menu.copyright))
    end

    -- show logo
    option.show_logo()

    -- print usage
    if main.usage then
        io.print("")
        io.print(colors.translate("${bright}Usage: $${default color.menu.usage}" .. main.usage .. "${clear}"))
    end

    -- print description
    if main.description then
        io.print("")
        io.print(main.description)
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
            io.print("")
            io.print(colors.translate(string.format("${bright}%s%ss: ", string.sub(categoryname, 1, 1):upper(), string.sub(categoryname, 2))))

            -- the padding spaces
            local padding = 42

            -- get width of console
            local console_width = math.max(os.getwinsize().width, 80)

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

                -- append color
                taskline = colors.translate("${color.menu.main.task.name}" .. taskline .. "${clear}")

                -- append the task description
                if taskinfo.description then
                    taskline = option._inwidth_append(taskline, taskinfo.description, padding + 1 - 18, console_width, console_width - padding - 1 + 18)
                end

                -- print task line
                io.print(colors.translate(taskline))
            end
        end
    end

    -- print options
    if main.options then
        option.show_options(main.options, "build")
    end
end  

-- show the options menu 
function option.show_options(options, taskname)

    -- check
    assert(options)

    -- the padding spaces
    local padding = 42

    -- remove repeat empty lines
    local is_action = false
    local emptyline_count = 0
    local printed_options = {}
    for _, opt in ipairs(options) do
        if not opt[1] and not opt[2] then
            emptyline_count = emptyline_count + 1
        else
            emptyline_count = 0
        end
        if emptyline_count < 2 then
            table.insert(printed_options, opt)
        end
        if opt.category and opt.category == "action" then
            is_action = true
        end
    end

    -- print header
    io.print("")
    if is_action then
        io.print(colors.translate("${bright}Common options: "))
    else
        io.print(colors.translate("${bright}Options: "))
    end

    -- print options
    options = printed_options
    for _, opt in ipairs(options) do

        -- the following options are belong action? show command section
        --
        -- @see core/base/task.lua: translate menu
        --
        if opt.category and opt.category == "action" then
            io.print("")
            io.print(colors.translate("${bright}Command options (" .. taskname .. "): "))
        end
        
        -- init the option info
        local option_info   = ""

        -- append the shortname
        local shortname = opt[1]
        local name      = opt[2]
        local mode      = opt[3]
        local default   = opt[4]
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
            elseif mode == "vs" then
                option_info = option_info .. "    " .. name .. " ..."
            else
                option_info = option_info .. option._ifelse(shortname, ", --", "        --") .. name
            end
            if mode == "kv" then
                option_info = option_info .. "=" .. option._ifelse(type(default) == "boolean", "[y|n]", name:upper())
            end
        elseif mode == "v" or mode == "vs" then
            option_info = option_info .. "    ..."
        end

        -- append spaces
        for i = (#option_info), padding do
            option_info = option_info .. " "
        end

        -- append color
        option_info = colors.translate("${color.menu.option.name}" .. option_info .. "${clear}")

        -- get width of console
        local console_width = math.max(os.getwinsize().width, 80)

        -- append the option description
        local description = opt[5]
        if description then
            option_info = option._inwidth_append(option_info, description, padding + 1, console_width, console_width - padding - 1)
        end

        -- append the default value
        if default then
            local defaultval = tostring(default)
            if type(default) == "boolean" then
                defaultval = option._ifelse(default, "y", "n")
            end
            option_info  = option._inwidth_append(option_info, " (default: ", padding + 1, console_width)
            local origin_width = option._get_linelen(option_info)
            option_info  = option_info .. "${bright}"
            option_info  = option._inwidth_append(option_info, defaultval, padding + 1, console_width, console_width - origin_width)
            origin_width = option._ifelse(origin_width + #defaultval > console_width, option._get_linelen(option_info), origin_width + (#(tostring(default))))
            option_info  = option_info .. "${clear}"
            option_info  = option._inwidth_append(option_info, ")", padding + 1, console_width, console_width - origin_width)
        end

        -- print option info
        io.print(colors.translate(option_info))

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
                io.print(option._inwidth_append(spaces, description, padding + 1, console_width))

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
                    io.print(option._inwidth_append(spaces, v, padding + 1, console_width))
                end
            end
        end

        -- print values
        local values = opt.values
        if type(values) == "function" then
            values = values()
        end
        if values then
            
            for _, value in ipairs(table.wrap(values)) do

                -- make spaces 
                local spaces = ""
                for i = 0, padding do
                    spaces = spaces .. " "
                end

                -- print this value
                io.print(option._inwidth_append(spaces, "    - " .. tostring(value), padding + 1, console_width))
            end
        end
    end
end  

-- return module: option
return option
