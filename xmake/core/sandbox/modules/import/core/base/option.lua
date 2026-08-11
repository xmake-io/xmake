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
-- Copyright (C) 2015-present, Xmake Open Source Community.
--
-- @author      ruki
-- @file        option.lua
--

-- load modules
local table  = require("base/table")
local option = require("base/option")
local raise  = require("sandbox/modules/raise")

-- define module
local sandbox_core_base_option = sandbox_core_base_option or {}

-- inherit some builtin interfaces
sandbox_core_base_option.get      = option.get
sandbox_core_base_option.set      = option.set
sandbox_core_base_option.default  = option.default
sandbox_core_base_option.save     = option.save
sandbox_core_base_option.restore  = option.restore
sandbox_core_base_option.boolean  = option.boolean
sandbox_core_base_option.taskname = option.taskname
sandbox_core_base_option.taskmenu = option.taskmenu

-- get the options
function sandbox_core_base_option.options()
    return assert(option.options())
end

-- get the defaults
function sandbox_core_base_option.defaults()
    return option.defaults() or {}
end

-- show logo
function sandbox_core_base_option.show_logo(logo, opt)
    option.show_logo(logo, opt)
end

-- show options
function sandbox_core_base_option.show_options(options, taskname)
    option.show_options(options, taskname)
end

-- parse arguments with the given options
function sandbox_core_base_option.raw_parse(argv, options, opt)
    assert(argv and options)

    -- parse it
    local results, errors = option.parse(argv, options, opt)
    if not results then
        raise(errors)
    end
    return results
end

-- parse arguments with the given options
function sandbox_core_base_option.parse(argv, options, ...)
    assert(argv and options)

    -- add common options
    table.insert(options, 1, {})
    table.insert(options, 2, {'h', "help",      "k",  nil, "Print this help message and exit." })
    table.insert(options, 3, {})

    -- show help
    local descriptions = {...}
    local function show_help()
        for _, description in ipairs(descriptions) do
            print(description)
        end
        option.show_options(options)
    end

    -- parse it
    local results, errors = option.parse(argv, options)
    if not results then
        show_help()
        raise(errors)
    end

    -- help?
    if results.help then
        show_help()
        os.exit()
    else
        results.help = show_help
    end
    return results
end

-- return module
return sandbox_core_base_option
