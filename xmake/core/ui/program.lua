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
-- @file        program.lua
--

-- load modules
local log    = require("ui/log")
local rect   = require("ui/rect")
local point  = require("ui/point")
local panel  = require("ui/panel")
local event  = require("ui/event")
local curses = require("ui/curses")

-- define module
local program = program or panel()

-- init program
function program:init(name, argv)

    -- init main window
    local main_window = self:main_window()

    -- disable echo
    curses.echo(false)

    -- disable input cache
    curses.cbreak(true)

    -- disable newline
    curses.nl(false)

    -- init mouse support
    if curses.KEY_MOUSE then
        curses.mousemask(curses.ALL_MOUSE_EVENTS)
    end

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

    -- save the current arguments
    self._ARGV = argv

    -- init panel
    panel.init(self, name, rect {0, 0, curses.columns(), curses.lines()})

    -- init state
    self:state_set("focused", true)
    self:state_set("selected", true)
end

-- exit program
function program:exit()

    -- exit panel
    panel.exit(self)

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

-- get the current event
function program:event()

    -- get event from the event queue first
    local event_queue = self._EVENT_QUEUE
    if event_queue then
        local e = event_queue[1]
        if e then
            table.remove(event_queue, 1)
            return e
        end
    end

    -- get input key
    local key_code, key_name, key_meta = self:_input_key()
    if key_code then
        if curses.KEY_MOUSE and key_code == curses.KEY_MOUSE then
            local code, x, y = curses.getmouse()
            local name = self:_mouse_map()[code]
            return event.mouse{code, x, y, name}
        end
        return event.keyboard{key_code, key_name, key_meta}
    end
end

-- on event
function program:on_event(e)

    -- get the top focused view
    local focused_view = self
    while focused_view:type() == "panel" and focused_view:current() do
        focused_view = focused_view:current()
    end

    -- do event for focused views
    while focused_view and focused_view ~= self do
        local parent = focused_view:parent()
        if focused_view:on_event(e) then
            return true
        end
        focused_view = parent
    end

    -- do event
    if e.type == event.ev_keyboard then
        -- resize?
        if e.key_name == "Resize" then
            self:bounds_set(rect {0, 0, curses.columns(), curses.lines()})
            return true
        -- refresh?
        elseif e.key_name == "Refresh" then
            self:invalidate()
            return true
        -- ctrl+c? quit program
        elseif e.key_name == "CtrlC" then
            self:send("cm_exit")
            return true
        end
    -- quit program?
    elseif event.is_command(e, "cm_exit") then
        self:quit()
        return true
    end
end

-- put an event to view
function program:put_event(e)

    -- init event queue
    self._EVENT_QUEUE = self._EVENT_QUEUE or {}

    -- put event to queue
    table.insert(self._EVENT_QUEUE, e)
end

-- send command
function program:send(command, extra)
    self:put_event(event.command {command, extra})
end

-- quit program
function program:quit()
    self:send("cm_quit")
end

-- run program loop
function program:loop(argv)

    -- do message loop
    local e = nil
    local sleep = true
    while true do

        -- get the current event
        e = self:event()

        -- do event
        if e then
            event.dump(e)
            self:on_event(e)
            sleep = false
        else
            -- do idle event
            self:on_event(event.idle())
            sleep = true
        end

        -- quit?
        if e and event.is_command(e, "cm_quit") then
            break
        end

        -- resize views
        if self:state("resize") then
            self:on_resize()
        end

        -- draw views
        self:on_draw()

        -- refresh views
        if self:state("refresh") then
            self:on_refresh()
        end

        -- wait some time, 50ms
        if sleep then
            curses.napms(50)
        end
    end
end

-- refresh program
function program:on_refresh()

    -- refresh views
    panel.on_refresh(self)

    -- trace
    log:print("%s: refresh ..", self)

    -- get main window
    local main_window = curses.main_window()

    -- refresh main window
    self:window():copy(main_window, 0, 0, 0, 0, self:height() - 1, self:width() - 1)

    -- refresh cursor
    self:_refresh_cursor()

    -- mark as refresh
    main_window:noutrefresh()

    -- do update
    curses.doupdate()
end

-- get key map
function program:_key_map()
    if not self._KEYMAP then
        self._KEYMAP =
        {
            [ 1] = "CtrlA", [ 2] = "CtrlB", [ 3] = "CtrlC",
            [ 4] = "CtrlD", [ 5] = "CtrlE", [ 6] = "CtrlF",
            [ 7] = "CtrlG", [ 8] = "CtrlH", [ 9] = "CtrlI",
            [10] = "CtrlJ", [11] = "CtrlK", [12] = "CtrlL",
            [13] = "CtrlM", [14] = "CtrlN", [15] = "CtrlO",
            [16] = "CtrlP", [17] = "CtrlQ", [18] = "CtrlR",
            [19] = "CtrlS", [20] = "CtrlT", [21] = "CtrlU",
            [22] = "CtrlV", [23] = "CtrlW", [24] = "CtrlX",
            [25] = "CtrlY", [26] = "CtrlZ",

            [  8] = "Backspace",
            [  9] = "Tab",
            [ 10] = "Enter",
            [ 13] = "Enter",
            [ 27] = "Esc",
            [ 31] = "CtrlBackspace",
            [127] = "Backspace",

            [curses.KEY_DOWN        ] = "Down",
            [curses.KEY_UP          ] = "Up",
            [curses.KEY_LEFT        ] = "Left",
            [curses.KEY_RIGHT       ] = "Right",
            [curses.KEY_HOME        ] = "Home",
            [curses.KEY_END         ] = "End",
            [curses.KEY_NPAGE       ] = "PageDown",
            [curses.KEY_PPAGE       ] = "PageUp",
            [curses.KEY_IC          ] = "Insert",
            [curses.KEY_DC          ] = "Delete",
            [curses.KEY_BACKSPACE   ] = "Backspace",
            [curses.KEY_F1          ] = "F1",
            [curses.KEY_F2          ] = "F2",
            [curses.KEY_F3          ] = "F3",
            [curses.KEY_F4          ] = "F4",
            [curses.KEY_F5          ] = "F5",
            [curses.KEY_F6          ] = "F6",
            [curses.KEY_F7          ] = "F7",
            [curses.KEY_F8          ] = "F8",
            [curses.KEY_F9          ] = "F9",
            [curses.KEY_F10         ] = "F10",
            [curses.KEY_F11         ] = "F11",
            [curses.KEY_F12         ] = "F12",

            [curses.KEY_RESIZE      ] = "Resize",
            [curses.KEY_REFRESH     ] = "Refresh",

            [curses.KEY_BTAB        ] = "ShiftTab",
            [curses.KEY_SDC         ] = "ShiftDelete",
            [curses.KEY_SIC         ] = "ShiftInsert",
            [curses.KEY_SEND        ] = "ShiftEnd",
            [curses.KEY_SHOME       ] = "ShiftHome",
            [curses.KEY_SLEFT       ] = "ShiftLeft",
            [curses.KEY_SRIGHT      ] = "ShiftRight",
        }
    end
    return self._KEYMAP
end

-- get mouse map
function program:_mouse_map()
    if not self._MOUSEMAP then
        -- must be defined dynamically since it depends
        -- on curses implementation
        self._MOUSEMAP = {}
        for n, v in pairs(curses) do
            if (n:match('MOUSE') and n ~= 'KEY_MOUSE') or n:match('BUTTON') then
                self._MOUSEMAP[v] = n
            end
        end
    end
    return self._MOUSEMAP
end

-- get input key
function program:_input_key()

    -- get main window
    local main_window = self:main_window()

    -- get input character
    local ch = main_window:getch()
    if not ch then
        return
    end

    -- this is the time limit in ms within Esc-key sequences are detected as
    -- Alt-letter sequences. useful when we can't generate Alt-letter sequences
    -- directly. sometimes this pause may be longer than expected since the
    -- curses driver may also pause waiting for another key (ncurses-5.3)
    local esc_delay = 400

    -- get key map
    local key_map = self:_key_map()

    -- is alt?
    local alt = ch == 27
    if alt then

        -- get the next input character
        ch = main_window:getch()
        if not ch then

            -- since there is no way to know the time with millisecond precision
            -- we pause the the program until we get a key or the time limit
            -- is reached
            local t = 0
            while true do
                ch = main_window:getch()
                if ch or t >= esc_delay then
                    break
                end

                -- wait some time, 50ms
                curses.napms(50)
                t = t + 50
            end

            -- nothing was typed... return Esc
            if not ch then
                return 27, "Esc", false
            end
        end
        if ch > 96 and ch < 123 then
            ch = ch - 32
        end
    end

    -- map character to key
    local key = key_map[ch]
    local key_name = nil
    if key then
        key_name = alt and "Alt".. key or key
    elseif (ch < 256) then
        key_name = alt and "Alt".. string.char(ch) or string.char(ch)
    else
        return ch, '(noname)', alt
    end

    -- return key info
    return ch, key_name, alt
end

-- refresh cursor
function program:_refresh_cursor()

    -- get the top focused view
    local focused_view = self
    while focused_view:type() == "panel" and focused_view:current() do
        focused_view = focused_view:current()
    end

    -- get the cursor state of the top focused view
    local cursor_state = 0
    if focused_view and focused_view:state("cursor_visible") then
        cursor_state = focused_view:state("block_cursor") and 2 or 1
    end

    -- get the cursor position
    local cursor = focused_view and focused_view:cursor()() or point{0, 0}
    if cursor_state ~= 0 then
        local v = focused_view
        while v:parent() do

            -- update the cursor position
            cursor:addxy(v:bounds().sx, v:bounds().sy)

            -- is cursor visible?
            if cursor.x < 0 or cursor.y < 0 or cursor.x >= v:parent():width() or cursor.y >= v:parent():height() then
                cursor_state = 0
                break
            end

            -- get the parent view
            v = v:parent()
        end
    end

    -- update the cursor state
    curses.cursor_set(cursor_state)

    -- get main window
    local main_window = curses.main_window()

    -- trace
    log:print("cursor(%s): %s, %d", focused_view, cursor, cursor_state)

    -- move cursor position
    if cursor_state ~= 0 then
        main_window:move(cursor.y, cursor.x)
    else
        main_window:move(self:height() - 1, self:width() - 1)
    end
end

-- return module
return program
