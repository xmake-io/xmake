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
-- @file        deprecated.lua
--

-- define module
local deprecated = deprecated or {}

-- add deprecated entry
function deprecated.add(newformat, oldformat, ...)

    -- the entries
    deprecated._ENTRIES = deprecated._ENTRIES or {}

    -- the old and new entries
    local old = string.format(oldformat, ...)
    local new = newformat and string.format(newformat, ...) or false

    -- add it
    deprecated._ENTRIES[old] = new
end

-- dump all deprecated entries
function deprecated.dump()

    -- lazy load modules to avoid loop
    local utils     = require("base/utils")
    local option    = require("base/option")

    -- dump one or more ..
    local index = 0
    deprecated._ENTRIES = deprecated._ENTRIES or {}
    for old, new in pairs(deprecated._ENTRIES) do

        -- trace
        if index == 0 then
            print("")
        end

        -- show more?
        if not option.get("verbose") and index > 0 then
            utils.cprint("${bright color.warning}deprecated:${clear} add -v for getting more ..")
            break
        end

        if new then
            utils.cprint("${bright color.warning}deprecated:${clear} please uses %s instead of %s", new, old)
        else
            utils.cprint("${bright color.warning}deprecated:${clear} please remove %s", old)
        end
        index = index + 1
    end
end

-- return module
return deprecated
