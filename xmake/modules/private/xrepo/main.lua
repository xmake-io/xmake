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
-- @file        main.lua
--

-- imports
import("core.base.text")
import("core.base.option")

-- show version
function _show_version()

    -- show title
    cprint("${bright}xRepo %s/xmake, A cross-platform C/C++ package manager based on Xmake.", xmake.version())

    -- show copyright
    cprint("Copyright (C) 2015-present Ruki Wang, ${underline}tboox.org${clear}, ${underline}xmake.io${clear}")
    print("")

    -- show logo
    local logo = [[
    __  ___ ___  ______ ____  _____
    \ \/ / |  _ \| ____|  _ \/  _  |
     >  <  | |_) |  _| | |_) | |_| |
    /_/\_\_| \___|_____|_|   |____/

                         by ruki, xmake.io
    ]]
    option.show_logo(logo, {seed = 680})
end

-- get main menu options
function _menu_options()

    -- main menu options
    local options = {}

    -- show menu in narrow mode?
    local function menu_isnarrow()
        local width = os.getwinsize().width
        return width > 0 and width < 60
    end

    -- show all actions
    local function show_actions()
        print("")
        cprint("${bright}Actions:")

        -- get action names
        local repo_actions = {}
        local package_actions = {}
        for _, scriptfile in ipairs(os.files(path.join(os.scriptdir(), "action", "*.lua"))) do
            local action_name = path.basename(scriptfile)
            if action_name:endswith("-repo") then
                table.insert(repo_actions, action_name)
            else
                table.insert(package_actions, action_name)
            end
        end
        table.sort(repo_actions)
        table.sort(package_actions)

        -- make action content
        local tablecontent = {}
        local narrow = menu_isnarrow()
        for _, action_name in ipairs(table.join(package_actions, repo_actions)) do
            local action = import("private.xrepo.action." .. action_name, {anonymous = true})
            local _, _, description = action.menu_options()
            local taskline = string.format(narrow and "  %s" or "    %s", action_name)
            table.insert(tablecontent, {taskline, description})
        end

        -- set table styles
        tablecontent.style = {"${color.menu.main.task.name}"}
        tablecontent.width = {nil, "auto"}
        tablecontent.sep = narrow and "  " or "    "

        -- print table
        io.write(text.table(tablecontent))
    end

    -- show options of main program
    local function show_options()

        -- show usage
        cprint("${bright}Usage: $${clear cyan}xrepo [action] [options]")

        -- show actions
        show_actions()

        -- show options
        option.show_options(options, "main")
    end
    return options, show_options
end

-- parse options
function _parse_options(...)

    -- get action and arguments
    local argv = table.pack(...)
    local action_name = nil
    if #argv > 0 and not argv[1]:startswith('-') then
        action_name = argv[1]
        argv = table.slice(argv, 2)
    end

    -- get menu
    local action, options, show_options
    if action_name then
        action = assert(import("private.xrepo.action." .. action_name, {anonymous = true, try = true}), "xrepo: action %s not found!", action_name)
        options, show_options = action.menu_options()
    else
        options, show_options = _menu_options()
    end

    -- insert common options
    local common_options =
    {
        {'q', "quiet",     "k", nil, "Quiet operation."                            },
        {'y', "yes",       "k", nil, "Input yes by default if need user confirm."  },
        {nil, "root",      "k", nil, "Allow to run xrepo as root."                 },
        {},
        {'v', "verbose",   "k", nil, "Print lots of verbose information for users."},
        {'D', "diagnosis", "k", nil, "Print lots of diagnosis information."        },
        {nil, "version",   "k", nil, "Print the version number and exit."          },
        {'h', "help",      "k", nil, "Print this help message and exit."           },
        {category = action and "action" or nil},
    }
    for _, opt in irpairs(common_options) do
        table.insert(options, 1, opt)
    end

    -- parse argument options
    local menu = {}
    local results, errors = option.raw_parse(argv, options)
    if results then
        menu.options = results
    end
    menu.action      = action
    menu.action_name = action_name
    menu.show_help   = function ()
        _show_version()
        show_options()
    end
    return menu, errors
end

-- main entry
function main(...)

    -- parse argument options
    local menu, errors = _parse_options(...)
    if errors then
        menu.show_help()
        raise(errors)
    end

    -- show help?
    local options = menu.options
    if not options or options.help then
        return menu.show_help()
    end

    -- show version?
    if options.version then
        return _show_version()
    end

    -- init option
    option.save()
    for k, v in pairs(options) do
        option.set(k, v)
    end

    -- tell xmake that xrepo is currently being used
    os.setenv("XREPO_WORKING", "y")

    -- do action
    if menu.action then
        menu.action()
    else
        menu.show_help()
    end
end
