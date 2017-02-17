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
-- @file        utils.lua
--

-- define module
local utils = utils or {}

-- load modules
local option = require("base/option")
local colors = require("base/colors")
local string = require("base/string")

-- print string with newline
function utils._print(...)

    -- print it if not quiet
    if not option.get("quiet") then
        print(...)
    end
end

-- print string without newline
function utils._iowrite(...)

    -- print it if not quiet
    if not option.get("quiet") then
        io.write(...)
    end
end

-- print format string with newline
function utils.print(format, ...)

    -- check
    assert(format)

    -- trace
    utils._print(string.tryformat(format, ...))
end

-- print format string without newline
function utils.printf(format, ...)

    -- check
    assert(format)

    -- trace
    utils._iowrite(string.tryformat(format, ...))
end

-- print format string and colors with newline
function utils.cprint(format, ...)

    -- check
    assert(format)

    -- trace
    utils._print(colors(string.tryformat(format, ...)))
end

-- print format string and colors without newline
function utils.cprintf(format, ...)

    -- check
    assert(format)

    -- trace
    utils._iowrite(colors(string.tryformat(format, ...)))
end

-- the verbose function
function utils.verbose(format, ...)

    -- enable verbose?
    if option.get("verbose") and format ~= nil then
        
        -- trace
        utils._print(string.tryformat(format, ...))
    end
end

-- the verbose error function
function utils.verror(format, ...)

    -- enable verbose?
    if option.get("verbose") and format ~= nil then
        
        -- trace
        utils.cprint("${bright red}error: ${default red}" .. string.tryformat(format, ...))
    end
end

-- the error function
function utils.error(format, ...)

    -- trace
    if format ~= nil then
        utils.cprint("${bright red}error: ${default red}" .. string.tryformat(format, ...))
    end
end

-- the warning function
function utils.warning(format, ...)

    -- check
    assert(format)

    -- format message
    local msg = "${bright yellow}warning: ${default yellow}" .. string.tryformat(format, ...)

    -- init warnings
    utils._WARNINGS = utils._WARNINGS or {}
    local warnings = utils._WARNINGS

    -- trace only once
    if not warnings[msg] then
        utils.cprint(msg)
        warnings[msg] = true
    end
end

-- ifelse, a? b : c
function utils.ifelse(a, b, c)
    if a then return b else return c end
end

-- call functions 
function utils.call(funcs, pred, ...)

    -- check
    assert(funcs)

    -- call all
    for _, func in ipairs(table.wrap(funcs)) do
        
        -- check
        assert(type(func) == "function")

        -- call it
        local result = func(...)

        -- exists predicate?
        if pred and type(pred) == "function" then
            if not pred(name, result) then return false end
        -- failed?
        elseif not result then return false end
    end

    -- ok
    return true
end

-- return module
return utils
