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
-- @file        program.lua
--

--[[ Console User Interface (cui) ]-----------------------------------------
Author: Tiago Dionizio (tiago.dionizio AT gmail.com)
$Id: program.lua 18 2007-06-21 20:43:52Z tngd $
--------------------------------------------------------------------------]]

-- load modules
local rect   = require("ui/rect")
local group  = require("ui/group")
local curses = require("ui/curses")

-- define module
local program = program or group()

-- init program
function program:init()

    -- init main window
    local main_window = self:main_window()

    -- disable echo
    curses.echo(false)

    -- disable input cache
    curses.cbreak(true)

    -- disable newline
    curses.nl(false)

    -- to filter characters being output to the screen
    -- this will filter all characters where a chtype or chstr is used
    curses.map_output(true)

    -- on WIN32 ALT keys need to be mapped, so to make sure you get the wanted keys,
    -- only makes sense when using keypad(true) and echo(false)
    curses.map_keyboard(true)

    -- init colors
    if (curses.has_colors()) then 
        curses.start_color() 
    end

    -- disable main window cursor
    main_window:leaveok(false)

    -- enable special key map
    main_window:keypad(true)

    -- non-block for getch()
    main_window:nodelay(true)

    -- get 8-bits character for getch()
    main_window:meta(true)

    -- init group
    group.init(self, rect {0, 0, curses.columns(), curses.lines()})
end

-- exit program
function program:exit()

    -- exit group
    group.exit(self)

    -- (attempt to) make sure the screen will be cleared
    -- if not restored by the curses driver
    self:main_window():clear()
    self:main_window():noutrefresh()
    curses.doupdate()

    -- exit curses
    assert(not curses.isdone())
    curses.done()
end

-- get the main window
function program:main_window()

    -- init main window if not exists
    local main_window = self._MAIN_WINDOW
    if not main_window then
        
        -- init main window
        main_window = curses.init()
        assert(main_window, "cannot init main window!")

        -- save main window
        self._MAIN_WINDOW = main_window
    end
    return main_window
end

-- get the command arguments
function program:argv()
    return self._ARGV
end

-- run program
function program:run(argv)

    -- save the current arguments
    self._ARGV = argv

    -- execute group
    self:execute()
end

-- return module
return program
