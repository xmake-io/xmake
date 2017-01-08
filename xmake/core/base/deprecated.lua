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
-- @file        deprecated.lua
--

-- define module
local deprecated = deprecated or {}

-- load modules
local utils     = require("base/utils")
local table     = require("base/table")
local string    = require("base/string")
local option    = require("base/option")

-- add deprecated entry
function deprecated.add(newformat, oldformat, ...)

    -- the entries
    deprecated._ENTRIES = deprecated._ENTRIES or {}

    -- the old and new entries
    local old = string.format(oldformat, ...)
    local new = string.format(newformat, ...)

    -- add it
    deprecated._ENTRIES[old] = new
end

-- dump all deprecated entries
function deprecated.dump()

    -- the entries
    deprecated._ENTRIES = deprecated._ENTRIES or {}

    -- dump all
    local index = 0
    for old, new in pairs(deprecated._ENTRIES) do

        -- trace newline
        if index == 0 then
            print("")
        end

        -- trace
        utils.cprint("${bright yellow}deprecated: ${default yellow}please uses %s instead of %s", new, old)

        -- too much?
        if index > 6 and not option.get("verbose") then
            utils.cprint("${bright yellow}deprecated: ${default yellow}add -v for getting more ..")
            break
        end

        -- update index
        index = index + 1
    end
end

-- return module
return deprecated
