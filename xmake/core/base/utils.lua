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

-- define module
local utils = utils or {}

-- load modules
local option = require("base/option")
local colors = require("base/colors")
local string = require("base/string")
local log    = require("base/log")
local io     = require("base/io")
local dump   = require("base/dump")
local text   = require("base/text")

-- dump values
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
        io.write(string.format("dump from %s %s:%s\n", info.name or "<anonymous>", info.source, line))
    end

    local values = table.pack(...)
    if values.n == 0 then
        return
    end

    if values.n == 1 then
        dump(values[1], "", diagnosis)
    else
        for i = 1, values.n do
            dump(values[i], string.format("%2d: ", i), diagnosis)
        end
    end

    return table.unpack(values, 1, values.n)
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

-- decode errors if errors is encoded table string
function utils._decode_errors(errors)
    if not errors then
        return
    end
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
        local errors = string.tryformat(format, ...)
        local decoded_errors = utils._decode_errors(errors)
        if decoded_errors then
            errors = tostring(decoded_errors)
        end
        utils.cprint("${bright color.error}${text.error}: ${clear}" .. errors)
        log:flush()
    end
end

-- add warning message
function utils.warning(format, ...)

    -- check
    assert(format)

    -- format message
    local args = table.pack(...)
    local msg = (args.n > 0 and string.tryformat(format, ...) or format)

    -- init warnings
    local warnings = utils._WARNINGS
    if not warnings then
        warnings = {}
        utils._WARNINGS = warnings
    end

    -- add warning msg
    table.insert(warnings, msg)
end

-- show warnings
function utils.show_warnings()
    local warnings = utils._WARNINGS
    if warnings then
        for idx, msg in ipairs(table.unique(warnings)) do
            if not option.get("verbose") and idx > 1 then
                utils.cprint("${bright color.warning}${text.warning}: ${color.warning}add -v for getting more warnings ..")
                break
            end
            utils.cprint("${bright color.warning}${text.warning}: ${color.warning}%s", msg)
        end
    end
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
            local decoded_errors = utils._decode_errors(errors)
            if decoded_errors then
                return decoded_errors
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
        utils.cprint("please input: ${bright}%s${clear} (y/n)", default and "y" or "n")

        -- get answer
        io.flush()
        confirm = option.boolean((io.read() or "false"):trim())
        if type(confirm) ~= "boolean" then
            confirm = default
        end
    end
    return confirm
end

function utils.table(data, opt)
    utils.printf(text.table(data, opt))
end

function utils.vtable(data, opt)
    utils.vprintf(text.table(data, opt))
end

-- return module
return utils
