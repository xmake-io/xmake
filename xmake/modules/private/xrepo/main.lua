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
-- @file        main.lua
--

-- imports
import("core.base.option")

-- main menu options
local _main_options =
{
    {},
    {'h', "help",      "k",  nil, "Print this help message and exit." },
    {},
    {nil, "action",    "v",  nil, "The sub-command name."    },
    {nil, "options",   "vs", nil, "The sub-command options." }
}

-- show help menu of main program
function _main_show_help()

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
    option.show_logo(logo, {seed = 680, bright = true})

    -- show usage
    cprint("${bright}Usage: $${clear cyan}xrepo [action] [options]")

    -- show options
    option.show_options(_main_options)
end

-- parse options
function _parse_options(...)

    -- get action and arguments
    local argv = table.pack(...)
    local action = nil
    if #argv > 0 and not argv[1]:startswith('-') then
        action = argv[1]
        argv = table.slice(argv, 2)
    end

    -- parse argument options
    local opt, errors = option.raw_parse(argv, _main_options)
    if opt then
        opt.action = action
    end
    return opt, errors
end

-- main entry
function main(...)

    -- parse argument options
    local mainopt, errors = _parse_options(...)
    if not mainopt then
        _main_show_help() -- TODO
        raise(errors)
    end

    -- help?
    if mainopt.help or not mainopt.action then
        _main_show_help()
        return
    end
end
