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
-- @file        filter.lua
--

-- define module: filter
local filter = filter or {}

-- load modules
local os        = require("base/os")
local winos     = require("base/winos")
local table     = require("base/table")
local utils     = require("base/utils")
local string    = require("base/string")
local scheduler = require("base/scheduler")

-- globals
local escape_table1 = {["$"] = "\001", ["("] = "\002", [")"] = "\003", ["%"] = "\004"}
local escape_table2 = {["\001"] = "$", ["\002"] = "(", ["\003"] = ")", ["\004"] = "%"}

-- new filter instance
function filter.new()

    -- init an filter instance
    local self = table.inherit(filter)

    -- init handler
    self._HANDLERS = {}

    -- ok
    return self
end

-- filter the shell command
--
-- e.g.
--
-- print("$(shell echo hello xmake)")
-- add_ldflags("$(shell pkg-config --libs sqlite3)")
--
function filter.shell(cmd)

    -- empty?
    if #cmd == 0 then
        os.raise("empty $(shell)!")
    end

    -- run shell
    scheduler:enable(false) -- disable coroutine scheduler to fix `attempt to yield across C-call boundary` when call gsub -> yield
    local ok, outdata, errdata = os.iorun(cmd)
    scheduler:enable(true)
    if not ok then
        os.raise("run $(shell %s) failed, errors: %s", cmd, errdata or "")
    end

    -- trim it
    if outdata then
        outdata = outdata:trim()
    end

    -- return the shell result
    return outdata
end

-- filter the environment variables
function filter.env(name)
    return os.getenv(name)
end

-- filter the winreg path
function filter.reg(path)

    -- must be windows
    if os.host() ~= "windows" then
        return
    end

    -- query registry value
    return (winos.registry_query(path))
end

-- set handlers
function filter:set_handlers(handlers)
    self._HANDLERS = handlers
end

-- get handlers
function filter:handlers()
    return self._HANDLERS
end

-- register handler
function filter:register(name, handler)
    self._HANDLERS[name] = handler
end

-- get variable value
function filter:get(variable)

    -- check
    assert(variable)

    -- is shell?
    if variable:startswith("shell ") then
        return filter.shell(variable:sub(7))
    -- is environment variable?
    elseif variable:startswith("env ") then
        return filter.env(variable:sub(5))
    elseif variable:startswith("reg ") then
        return filter.reg(variable:sub(5))
    end

    -- parse variable:mode
    local varmode   = variable:split(':')
    local mode      = varmode[2]
    variable        = varmode[1]

    -- handler it
    local result = nil
    for name, handler in pairs(self._HANDLERS) do
        result = handler(variable)
        if result then
            break
        end
    end

    -- TODO need improve
    -- handle mode
    if mode and result then
        if mode == "upper" then
            result = result:upper()
        elseif mode == "lower" then
            result = result:lower()
        end
    end

    -- ok?
    return result
end

-- filter the builtin variables: "hello $(variable)" for string
--
-- e.g.
--
-- print("$(host)")
-- print("$(env PATH)")
-- print("$(shell echo hello xmake!)")
-- print("$(reg HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\XXXX;Name)")
--
function filter:handle(value)

    -- check
    assert(type(value) == "string")

    -- escape "%$", "%(", "%)", "%%" to "\001", "\002", "\003", "\004"
    value = value:gsub("%%([%$%(%)%%])", function (ch) return escape_table1[ch] end)

    -- filter the builtin variables
    local values = {}
    local variables = {}
    value:gsub("%$%((.-)%)", function (variable)
        table.insert(variables, variable)
    end)
    -- we cannot call self:get() in gsub, because it will trigger "attempt to yield a c-call boundary"
    for _, variable in ipairs(variables) do
        -- escape "%$", "%(", "%)", "%%" to "$", "(", ")", "%"
        local name = variable:gsub("[\001\002\003\004]", function (ch) return escape_table2[ch] end)
        values[variable] = self:get(name) or ""
    end
    value = value:gsub("%$%((.-)%)", function (variable)
        return values[variable]
    end)
    return value:gsub("[\001\002\003\004]", function (ch) return escape_table2[ch] end)
end

-- return module: filter
return filter
