--!The Make-like Build Utility based on Lua
--
-- Licensed to the Apache Software Foundation (ASF) under one
-- or more contributor license agreements.  See the NOTICE file
-- distributed with this work for additional information
-- regarding copyright ownership.  The ASF licenses this file
-- to you under the Apache License, Version 2.0 (the
-- "License"); you may not use this file except in compliance
-- with the License.  You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- 
-- Copyright (C) 2015 - 2017, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        option.lua
--

-- define module
local sandbox_core_base_option = sandbox_core_base_option or {}

-- load modules
local table  = require("base/table")
local option = require("base/option")
local raise  = require("sandbox/modules/raise")

-- get the option value
function sandbox_core_base_option.get(name)

    -- get it
    return option.get(name)
end

-- set the option value
function sandbox_core_base_option.set(name, value)

    -- set it
    option.set(name, value)
end

-- get the default option value
function sandbox_core_base_option.default(name)

    -- get it
    return option.default(name)
end

-- get the options
function sandbox_core_base_option.options()

    -- get it
    return assert(option.options())
end

-- get the defaults
function sandbox_core_base_option.defaults()

    -- get it
    return option.defaults() or {}
end

-- parse arguments with the given options
function sandbox_core_base_option.parse(argv, options, ...)

    -- check
    assert(argv and options)

    -- add common options
    table.insert(options, 1, {})
    table.insert(options, 2, {'h', "help",      "k",  nil, "Print this help message and exit." })
    table.insert(options, 3, {})

    -- parse it
    local results, errors = option.parse(argv, options)
    if not results then

        -- show descriptions
        for _, description in ipairs({...}) do
            print(description)
        end

        -- show options
        option.show_options(options)

        -- raise errors
        raise(errors)
    end

    -- help?
    if results.help then

        -- show descriptions
        for _, description in ipairs({...}) do
            print(description)
        end

        -- show options
        option.show_options(options)

        -- exit
        raise()
    end

    -- ok
    return results
end

-- save context
function sandbox_core_base_option.save(taskname)
    return option.save(taskname)
end

-- restore context
function sandbox_core_base_option.restore()
    option.restore()
end

-- return module
return sandbox_core_base_option
