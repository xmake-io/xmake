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
-- @file        utils.lua
--

-- load modules
local io         = require("base/io")
local os         = require("base/os")
local utils      = require("base/utils")
local colors     = require("base/colors")
local option     = require("base/option")
local log        = require("base/log")
local deprecated = require("base/deprecated")
local try        = require("sandbox/modules/try")
local catch      = require("sandbox/modules/catch")
local vformat    = require("sandbox/modules/vformat")

-- define module
local sandbox_utils = sandbox_utils or {}

-- inherit some builtin interfaces
sandbox_utils.dump    = utils.dump -- do not change to a function call to utils.dump since debug.getinfo is called in utils.dump to get caller info
sandbox_utils.confirm = utils.confirm
sandbox_utils.error   = utils.error
sandbox_utils.warning = utils.warning
sandbox_utils.trycall = utils.trycall
sandbox_utils.ifelse  = utils.ifelse

-- print each arguments
function sandbox_utils._print(...)

    -- format each arguments
    local args = {}
    for _, arg in ipairs({...}) do
        if type(arg) == "string" then
            table.insert(args, vformat(arg))
        else
            table.insert(args, arg)
        end
    end

    -- print multi-variables with raw lua action
    utils._print(unpack(args))

    -- write to the log file
    log:printv(unpack(args))
end

-- print format string with newline
-- print builtin-variables with $(var)
-- print multi-variables with raw lua action
--
function sandbox_utils.print(format, ...)

    -- print format string
    if type(format) == "string" and format:find("%", 1, true) then

        local args = {...}
        try
        {
            function ()
                -- attempt to format message
                local message = vformat(format, unpack(args))

                -- trace
                utils._print(message)

                -- write to the log file
                log:printv(message)
            end,
            catch
            {
                function (errors)
                    -- print multi-variables with raw lua action
                    sandbox_utils._print(format, unpack(args))
                end
            }
        }

    else
        -- print multi-variables with raw lua action
        sandbox_utils._print(format, ...)
    end
end

-- print format string and the builtin variables without newline
function sandbox_utils.printf(format, ...)

    -- init message
    local message = vformat(format, ...)

    -- trace
    utils._iowrite(message)

    -- write log to the log file
    log:write(message)
end

-- print format string, the builtin variables and colors with newline
function sandbox_utils.cprint(format, ...)

    -- init message
    local message = vformat(format, ...)

    -- trace
    utils._print(colors.translate(message))

    -- write log to the log file
    if log:file() then
        log:printv(colors.ignore(message))
    end
end

-- print format string, the builtin variables and colors without newline
function sandbox_utils.cprintf(format, ...)

    -- init message
    local message = vformat(format, ...)

    -- trace
    utils._iowrite(colors.translate(message))

    -- write log to the log file
    if log:file() then
        log:write(colors.ignore(message))
    end
end

-- print the verbose information
function sandbox_utils.vprint(format, ...)
    if option.get("verbose") then
        sandbox_utils.print(format, ...)
    end
end

-- print the verbose information without newline
function sandbox_utils.vprintf(format, ...)
    if option.get("verbose") then
        sandbox_utils.printf(format, ...)
    end
end

-- print the diagnosis information
function sandbox_utils.dprint(format, ...)
    if option.get("diagnosis") then
        sandbox_utils.print(format, ...)
    end
end

-- print the diagnosis information without newline
function sandbox_utils.dprintf(format, ...)
    if option.get("diagnosis") then
        sandbox_utils.printf(format, ...)
    end
end

-- print the warning information
function sandbox_utils.wprint(format, ...)
    utils.warning(vformat(format, ...))
end

-- assert
function sandbox_utils.assert(value, format, ...)
    if not value then
        if format ~= nil then
            os.raiselevel(2, format, ...)
        else
            os.raiselevel(2, "assertion failed!")
        end
    end
    return value
end

-- return module
return sandbox_utils

