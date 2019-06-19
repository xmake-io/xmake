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
-- @file        sandbox.lua
--

-- define module
local sandbox_core_sandbox = sandbox_core_sandbox or {}

-- load modules
local sandbox   = require("sandbox/sandbox")
local raise     = require("sandbox/modules/raise")
local try       = require("sandbox/modules/try")
local catch     = require("sandbox/modules/catch")
local utils     = require("base/utils")
local table     = require("base/table")
local history   = require("project/history")
local dump      = require("base/dump")

-- print variables for interactive mode
function sandbox_core_sandbox._interactive_dump(...)
    local values = table.pack(...)
    -- do not use #values since nil might be included
    if values.n <= 1 then
        dump(values[1], "< ")
        io.write("\n")
    else
        local fmt = "< %d: "
        if values.n >= 1000 then
            -- try `unpack({}, 1, 5000)`, wish you happy!
            fmt = "< %4d: "
        elseif values.n >= 100 then
            fmt = "< %3d: "
        elseif values.n >= 10 then
            fmt = "< %2d: "
        end
        for i = 1, values.n do
            dump(values[i], string.format(fmt, i))
            io.write("\n")
        end
    end
end

-- enter interactive mode
function sandbox_core_sandbox.interactive()

    -- get the current sandbox instance
    local instance = sandbox.instance()
    if not instance then
        raise("cannot get sandbox instance!")
    end

    -- fork a new sandbox
    local errors
    instance, errors = instance:fork()
    if not instance then
        raise(errors)
    end

    -- load repl history
    local replhistory = nil
    if readline then

        -- clear history
        readline.clear_history()

        -- load history
        replhistory = history("global.history"):load("replhistory") or {}
        for _, ln in ipairs(replhistory) do
            readline.add_history(ln)
        end
    end

    -- register dump function for interactive mode
    instance._PUBLIC["$interactive_dump"] = sandbox_core_sandbox._interactive_dump

    -- enter interactive mode with this new sandbox
    sandbox.interactive(instance._PUBLIC)

    -- save repl history if readline is enabled
    if readline then

        -- save to history
        local entries = readline.history_list()
        if #entries > #replhistory then
            for i = #replhistory + 1, #entries do
                history("global.history"):save("replhistory", entries[i].line)
            end
        end

        -- clear history
        readline.clear_history()
    end
end

-- get the filter of the current sandbox for the given script
function sandbox_core_sandbox.filter(script)

    -- get the current sandbox instance
    local instance = sandbox.instance(script)
    if not instance then
        raise("cannot get sandbox instance!")
    end

    -- get it
    return instance:filter()
end

-- return module
return sandbox_core_sandbox
