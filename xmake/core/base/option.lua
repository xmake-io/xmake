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
-- Copyright (C) 2015-present, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        option.lua
--

-- define module: option
local option = {}

-- load modules
local cli       = require("base/cli")
local table     = require("base/table")
local tty       = require("base/tty")
local colors    = require("base/colors")
local text      = require("base/text")

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

function option._modenarrow()
    -- show menu in narrow mode?
    local width = os.getwinsize().width
    return width > 0 and width < 60
end

-- get the top context
function option._context()

    -- the contexts
    local contexts = option._CONTEXTS
    if contexts then
        return contexts[#contexts]
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
    if not xmake._ARGS then
        xmake._ARGS = os.args(xmake._ARGV)
    end
    return "xmake " .. xmake._ARGS
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

        -- find the current task and save it
        for taskname, taskinfo in pairs(main.tasks) do
            if taskname == xmake._COMMAND or taskinfo.shortname == xmake._COMMAND then
                context.taskname = taskname
                break
            end
        end

        -- not found?
        if not context.taskname or not menu[context.taskname] then
            option.show_main()
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

        -- get mode and name
        local mode = o[3]
        local name = o[2]
        assert(o and ((mode ~= "v" and mode ~= "vs") or name))

        -- fill short flags
        if o[3] == "k" and o[1] then
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

                -- get mode and name
                local mode = o[3]
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

                -- get mode and name
                local mode = match_opt[3]
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
                    return nil, "invalid argument: " .. arg.value
                end
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
    if taskmenu then
        option.populate_defaults(taskmenu.options, defaults)
    end
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
function option.show_logo(logo, opt)

    -- define logo
    logo = logo or [[
                         _
    __  ___ __  __  __ _| | ______
    \ \/ / |  \/  |/ _  | |/ / __ \
     >  <  | \__/ | /_| |   <  ___/
    /_/\_\_|_|  |_|\__ \|_|\_\____|

                         by ruki, xmake.io
    ]]

    -- make rainbow for logo
    opt = opt or {}
    if tty.has_color24() or tty.has_color256() then
        local lines = {}
        local seed  = opt.seed or 236
        for _, line in ipairs(logo:split("\n")) do
            local i = 0
            local line2 = ""
            line:gsub(".", function (c)
                local code = tty.has_color24() and colors.rainbow24(i, seed) or colors.rainbow256(i, seed)
                line2 = string.format("%s${bright %s}%s", line2, code, c)
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
        io.print(colors.translate(taskmenu.description))
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
        io.print(colors.translate(main.description))
    end

    -- print tasks
    if main.tasks then

        local narrow = option._modenarrow()

        -- make task categories
        local categories = {}
        for taskname, taskinfo in pairs(main.tasks) do

            -- the category name
            local categoryname = taskinfo.category or "task"
            if categoryname == "main" then
                categoryname = "action"
            end

            -- the category task
            local category = categories[categoryname] or { name = categoryname, tasks = {} }
            categories[categoryname] = category

            -- add task to the category
            category.tasks[taskname] = taskinfo
        end

        -- sort categories
        categories = table.values(categories)
        table.sort(categories, function (a, b)
            if a.name == "action" then
                return true
            end
            return a.name < b.name
        end)

        -- dump tasks by categories
        local tablecontent = {}
        for _, category in ipairs(categories) do

            -- the category name and task
            assert(category.name and category.tasks)

            -- print category name
            table.insert(tablecontent, {})
            table.insert(tablecontent, {{string.format("%s%ss: ", string.sub(category.name, 1, 1):upper(), string.sub(category.name, 2)), style="${reset bright}"}})

            -- print tasks
            for taskname, taskinfo in pairs(category.tasks) do

                -- init the task line
                local taskline = string.format(narrow and "  %s%s" or "    %s%s",
                    taskinfo.shortname and (taskinfo.shortname .. ", ") or "   ",
                    taskname)
                table.insert(tablecontent, {taskline, colors.translate(taskinfo.description or "")})
            end
        end

        -- set table styles
        tablecontent.style = {"${color.menu.main.task.name}"}
        tablecontent.width = {nil, "auto"}
        tablecontent.sep = narrow and "  " or "    "

        -- print table
        io.write(text.table(tablecontent))
    end

    -- print options
    if main.options then
        option.show_options(main.options, "build")
    end
end

-- show the options menu
function option.show_options(options, taskname)
    assert(options)

    -- remove repeat empty lines
    local is_action = false
    local emptyline_count = 0
    local printed_options = {}
    for _, opt in ipairs(options) do
        if opt.category and printed_options[#printed_options].category then
            table.remove(printed_options)
        end
        table.insert(printed_options, opt)
        if opt.category and opt.category == "action" then
            is_action = true
        end
    end
    if printed_options[#printed_options].category then
        table.remove(printed_options)
    end

    -- narrow mode?
    local narrow = option._modenarrow()

    -- print header
    local tablecontent = {}
    table.insert(tablecontent, {})
    if is_action then
        table.insert(tablecontent, {{"Common options:", style="${reset bright}"}})
    else
        table.insert(tablecontent, {{"Options:", style="${reset bright}"}})
    end

    -- print options
    local categories = {}
    for _, opt in ipairs(printed_options) do
        if opt.category and opt.category == "action" then
            -- the following options are belong action? show command section
            --
            -- @see core/base/task.lua: translate menu
            --
            table.insert(tablecontent, {})
            table.insert(tablecontent, {{"Command options (" .. taskname .. "):", style="${reset bright}"}})
        elseif opt.category and opt.category ~= "." then
            local category_root = opt.category:split("/")[1]
            if not categories[category_root] then
                table.insert(tablecontent, {})
                table.insert(tablecontent, {{"Command options (" .. opt.category .. "):", style="${reset bright}"}})
                categories[category_root] = true
            end
        elseif opt[3] == nil then
            table.insert(tablecontent, {})
        else

            -- append the shortname
            local shortname = opt[1]
            local name      = opt[2]
            local mode      = opt[3]
            local default   = opt[4]

            local title1, title2
            local kvplaceholder = mode == "kv" and ((type(default) == "boolean") and "[y|n]" or(name and name:upper() or "XXX"))
            if shortname then
                if mode == "kv" then
                    title1 = "-" .. shortname .. " " .. kvplaceholder
                else
                    title1 = "-" .. shortname
                end
            end

            -- append the name
            if name then
                local leading = mode:startswith("k") and "--" or "  "
                local kv
                if mode == "k" then
                    kv = name
                elseif mode == "kv" then
                    kv = name .. "=" .. kvplaceholder
                elseif mode == "vs" then
                    kv = name .. " ..."
                else
                    kv = name
                end
                title2 = leading .. kv
            elseif mode == "v" or mode == "vs" then
                title2 = "    ..."
            end

            -- get description
            local optdespn = table.maxn(opt)
            local description = table.move(opt, 5, optdespn, 1, table.new(optdespn - 5 + 1, 0))
            if #description == 0 then
                description[1] = ""
            end

            -- transform description
            local desp_strs = table.new(#description, 0)
            for _, v in ipairs(description) do
                if type(v) == "function" then
                    v = v()
                end
                if type(v) == "string" then
                    table.insert(desp_strs, colors.translate(v))
                elseif type(v) == "table" then
                    table.move(v, 1, #v, #desp_strs + 1, desp_strs)
                end
            end

            -- append the default value
            if default then
                local defaultval = tostring(default)
                if type(default) == "boolean" then
                    defaultval = default and "y" or "n"
                end
                local def_desp = colors.translate(string.format(" (default: ${bright}%s${clear})", defaultval))
                desp_strs[1] = desp_strs[1] .. def_desp
            end

            -- append values
            local values = opt.values
            if type(values) == "function" then
                values = values(false, {helpmenu = true})
            end
            if values then
                for _, value in ipairs(table.wrap(values)) do
                    table.insert(desp_strs, "    - " .. tostring(value))
                end
            end

            -- insert row
            if narrow then
                if title1 then
                    table.insert(tablecontent, {{"  " .. title1, "   " .. title2 }, desp_strs})
                else
                    table.insert(tablecontent, {{"  " .. title2 }, desp_strs})
                end
            else
                if title1 then
                    table.insert(tablecontent, {"    " .. title1 .. ", " .. title2 , desp_strs})
                else
                    table.insert(tablecontent, {"        " .. title2 , desp_strs})
                end
            end
        end
    end

    -- set table styles
    tablecontent.style = {"${color.menu.option.name}"}
    tablecontent.width = {nil, "auto"}
    tablecontent.sep = narrow and "  " or "    "

    -- print table
    io.write(text.table(tablecontent))
end

-- return module: option
return option
