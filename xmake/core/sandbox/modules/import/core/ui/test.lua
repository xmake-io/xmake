--!A cross-platform build utility based on Lua
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
-- @file        linker.lua
--

-- define module
local sandbox_core_ui_test = sandbox_core_ui_test or {}

-- load modules
local log       = require("ui/log")
local curses    = require("ui/curses")
local raise     = require("sandbox/modules/raise")

function test()

    log:flush()
    curses.init()
    print(curses.color_pair("yellow", "red"))

    --[[
    curses.init()
    local blines = 5
    local olines = 10
    local lines, columns = curses.lines(), curses.columns()
    local stdscr = curses.main_window()
    -- create windows
    w_out = stdscr:sub(lines - blines - olines, columns, olines, 0)
    w_in = stdscr:sub(blines, columns, lines - blines, 0)

    -- auto refresh
    w_out:immedok(true)
    w_in:immedok(true)

    -- scroll region
    w_in:scrollok(true)
    w_out:scrollok(true)

    -- decoration
    w_out:mvhline(lines - blines - olines - 1, 0, curses.ACS_HLINE, columns)
    w_out:mvhline(0, 0, curses.ACS_HLINE, columns)
    w_out:move(1, 0)
    assert(w_out:wsetscrreg(1, lines - blines - olines - 2), "wsetscrreg")

    --w_out:wgetch()
    printx = function(...)
        for _, a in ipairs({...}) do
            w_out:addstr(tostring(a)..'\t')
        end
        w_out:addstr('\n')
    end


    local y, x, cmd, ok, msg
    while (1) do
        y, x = w_in:getyx() w_in:move(y, x) w_in:refresh()
        cmd = w_in:getstr()
        printx('> '..cmd)
        if (cmd == 'exit' or string.byte(cmd, 1, 1) == 4) then 
            break
        end
    end]]
end

function sandbox_core_ui_test.main()

    local ok, msg = pcall(test)
    curses.done()
    if not ok then 
        print(msg) 
    end
end

-- return module
return sandbox_core_ui_test
