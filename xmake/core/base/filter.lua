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
-- @file        filter.lua
--

-- define module: filter
local filter = filter or {}

-- load modules
local os        = require("base/os")
local table     = require("base/table")
local utils     = require("base/utils")
local string    = require("base/string")

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
-- .e.g
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
    local ok, outdata, errdata = os.iorun(cmd)
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
    return (winreg.query(path)) 
end

-- register handler
function filter:register(name, handler)

    -- set handler
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
-- .e.g  
--
-- print("$(host)")
-- print("$(env PATH)")
-- print("$(shell echo hello xmake!)")
-- print("$(reg HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\XXXX;Name)")
--
function filter:handle(value)

    -- check
    assert(type(value) == "string")

    -- filter the builtin variables
    return (value:gsub("%$%((.-)%)", function (variable) 
        return self:get(variable) or ""
    end))
end

-- return module: filter
return filter
