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
-- @file        tty.lua
--

-- define module
local tty = tty or {}

-- load modules
local io = require("base/io")

-- @see http://www.termsys.demon.co.uk/vtansi.htm

-- write control characters
function tty._iowrite(...)
    local isatty = tty._ISATTY
    if isatty == nil then
        isatty = io.isatty()
        tty._ISATTY = isatty
    end
    if isatty then
        io.write(...)
    end
end

-- erases from the current cursor position to the end of the current line.
function tty.erase_line_to_end()
    tty._iowrite("\x1b[K")
    return tty
end

-- erases from the current cursor position to the start of the current line.
function tty.erase_line_to_start()
    tty._iowrite("\x1b[1K")
    return tty
end

-- erases the entire current line
function tty.erase_line()
    tty._iowrite("\x1b[2K")
    return tty
end

-- erases the screen from the current line down to the bottom of the screen.
function tty.erase_down()
    tty._iowrite("\x1b[J")
    return tty
end

-- erases the screen from the current line up to the top of the screen.
function tty.erase_up()
    tty._iowrite("\x1b[1J")
    return tty
end

-- erases the screen with the background colour and moves the cursor to home.
function tty.erase_screen()
    tty._iowrite("\x1b[2J")
    return tty
end

-- save current cursor position.
function tty.cursor_save()
    tty._iowrite("\x1b[s")
    return tty
end

-- restores cursor position after a save cursor.
function tty.cursor_restore()
    tty._iowrite("\x1b[u")
    return tty
end

-- save current cursor position and color attrs
function tty.cursor_and_attrs_save()
    tty._iowrite("\x1b7")
    return tty
end

-- restores cursor position and color attrs after a save cursor.
function tty.cursor_and_attrs_restore()
    tty._iowrite("\x1b8")
    return tty
end

-- carriage return
function tty.cr()
    tty._iowrite("\r")
    return tty
end

-- flush control
function tty.flush()
    if io.isatty() then
        io.flush()
    end
    return tty
end

-- return module
return tty
