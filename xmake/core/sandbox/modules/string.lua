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
-- @file        string.lua
--

-- load modules
local string    = require("base/string")
local sandbox   = require("sandbox/sandbox")

-- define module
local sandbox_string = sandbox_string or {}

-- inherit the public interfaces of string
for k, v in pairs(string) do
    if not k:startswith("_") and type(v) == "function" then
        sandbox_string[k] = v
    end
end

-- format string with the builtin variables
function sandbox_string.vformat(format, ...)

    -- check
    assert(format)

    -- get the current sandbox instance
    local instance = sandbox.instance()
    assert(instance)

    -- format string if exists arguments
    local result = format
    if #{...} > 0 then

        -- escape "%$", "%(", "%)" to '$', '(', ')'
        format = format:gsub("%%([%$%(%)])", "%%%%%1")

        -- try to format it
        result = string.format(format, ...)
    end
    assert(result)

    -- get filter from the current sandbox
    local filter = instance:filter()
    if filter then
        result = filter:handle(result)
    end

    -- ok?
    return result
end

-- return module
return sandbox_string

