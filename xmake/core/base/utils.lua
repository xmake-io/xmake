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
-- Copyright (C) 2015 - 2019, TBOOX Open Source Group.
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
local log    = require("base/log")
local io     = require("base/io")
local dump   = require("base/dump")

-- dump value
function utils.dump(...)
    if option.get("quiet") then
        return ...
    end

    local diagnosis = option.get("diagnosis")

    -- show caller info
    if diagnosis then
        local info = debug.getinfo(2)
        local line = info.currentline
        if not line or line < 0 then line = info.linedefined end
        io.write(string.format("dump form %s %s:%s\n", info.name or "<anonymous>", info.source, line))
    end

    local values = table.pack(...)
    if values.n == 0 then
        return
    end
    local indent = nil
    local values_count = values.n
    values.n = nil
    -- use last input as indent if it is a string
    if values_count > 1 and type(values[values_count]) == "string" then
        indent = values[values_count]
        values[values_count] = nil
        values_count = values_count - 1
    end

    if values_count == 1 then
        dump(values[1], indent or "", diagnosis)
    else
        for i = 1, values_count do
            dump(values[i], indent or string.format("%2d: ", i), diagnosis)
        end
    end

    return table.unpack(values, 1, values_count)
end

-- print string with newline
function utils._print(...)

    -- print it if not quiet
    if not option.get("quiet") then
        local values = {...}
        for i, v in ipairs(values) do
            -- dump basic type
            if type(v) == "string" or type(v) == "boolean" or type(v) == "number" then
                io.write(tostring(v))
            -- dump table
            elseif type(v) == "table" then
                dump(v)
            else
                io.write("<" .. tostring(v) .. ">")
            end
            if i ~= #values then
                io.write(" ")
            end
        end
        io.write('\n')
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

    -- init message
    local message = string.tryformat(format, ...)

    -- trace
    utils._print(message)

    -- write to the log file
    log:printv(message)
end

-- print format string without newline
function utils.printf(format, ...)

    -- check
    assert(format)

    -- init message
    local message = string.tryformat(format, ...)

    -- trace
    utils._iowrite(message)

    -- write to the log file
    log:write(message)
end

-- print format string and colors with newline
function utils.cprint(format, ...)

    -- check
    assert(format)

    -- init message
    local message = string.tryformat(format, ...)

    -- trace
    utils._print(colors.translate(message))

    -- write to the log file
    if log:file() then
        log:printv(colors.ignore(message))
    end
end

-- print format string and colors without newline
function utils.cprintf(format, ...)

    -- check
    assert(format)

    -- init message
    local message = string.tryformat(format, ...)

    -- trace
    utils._iowrite(colors.translate(message))

    -- write to the log file
    if log:file() then
        log:write(colors.ignore(message))
    end
end

-- print the verbose information
function utils.vprint(format, ...)
    if (option.get("verbose") or option.get("diagnosis")) and format ~= nil then
        utils.print(format, ...)
    end
end

-- print the verbose information without newline
function utils.vprintf(format, ...)
    if (option.get("verbose") or option.get("diagnosis")) and format ~= nil then
        utils.printf(format, ...)
    end
end

-- print the error information
function utils.error(format, ...)
    if format ~= nil then
        utils.cprint("${bright color.error}${text.error}: ${clear}" .. string.tryformat(format, ...))
        log:flush()
    end
end

-- the warning function
function utils.warning(format, ...)

    -- check
    assert(format)

    -- format message
    local msg = "${bright color.warning}${text.warning}: ${color.warning}" .. string.tryformat(format, ...)

    -- init warnings
    utils._WARNINGS = utils._WARNINGS or {}
    local warnings = utils._WARNINGS

    -- trace only once
    if not warnings[msg] then
        utils.cprint(msg)
        warnings[msg] = true
    end

    -- flush
    log:flush()
end

-- ifelse, a? b : c
function utils.ifelse(a, b, c)
    if a then return b else return c end
end

-- try to call script
function utils.trycall(script, traceback, ...)
    return xpcall(script, function (errors)

            -- get traceback
            traceback = traceback or debug.traceback

            -- decode it if errors is encoded table string
            if errors then
                local _, pos = errors:find("[@encode(error)]: ", 1, true)
                if pos then
                    -- strip traceback (maybe from coroutine.resume)
                    local errs = errors:sub(pos + 1)
                    local stack = nil
                    local stackpos = errs:find("}\nstack traceback:", 1, true)
                    if stackpos and stackpos > 1 then
                        stack = errs:sub(stackpos + 2)
                        errs  = errs:sub(1, stackpos)
                    end
                    errors, errs = errs:deserialize()
                    if not errors then
                        errors = errs
                    end
                    if type(errors) == "table" then
                        if stack then
                            errors._stack = stack
                        end
                        setmetatable(errors, 
                        { 
                            __tostring = function (self)
                                local result = self.errors
                                if not result then
                                    result = string.serialize(self, {strip = true, indent = false})
                                end
                                result = result or ""
                                if self._stack then
                                    result = result .. "\n" .. self._stack
                                end
                                return result
                            end,
                            __concat = function (self, other)
                                return tostring(self) .. tostring(other)
                            end
                        })
                    end
                    return errors
                end
            end
            return traceback(errors)
        end, ...)
end

-- get confirm result
--
-- @code
-- if utils.confirm({description = "xmake.lua not found, try generating it", default = true}) then
--    TODO  
-- end
-- @endcode
--
function utils.confirm(opt)

    -- init options
    opt = opt or {}

    -- get default 
    local default = opt.default
    if default == nil then
        default = false
    end

    -- get description
    local description = opt.description or ""

    -- get confirm result
    local confirm = option.get("yes") or option.get("confirm")
    if type(confirm) == "string" then
        confirm = confirm:lower()
        if confirm == "d" or confirm == "def" then
            confirm = default
        else
            confirm = nil
        end
    end

    -- get user confirm
    if confirm == nil then

        -- show tips
        if type(description) == "function" then
            description()
        else
            utils.cprint("${bright color.warning}note: ${clear}%s (pass -y or --confirm=y/n/d to skip confirm)?", description)
        end
        utils.cprint("please input: %s (y/n)", default and "y" or "n")

        -- get answer
        io.flush()
        confirm = option.boolean(io.read():trim())
        if type(confirm) ~= "boolean" then
            confirm = default
        end
    end
    return confirm
end

-- return module
return utils
