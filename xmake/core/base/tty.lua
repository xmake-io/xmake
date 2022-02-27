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
-- @file        tty.lua
--

-- define module
local tty = tty or {}

-- load modules
local io = require("base/io")

-- save metatable and builtin functions
tty._term_mode = tty._term_mode or tty.term_mode

-- @see https://www2.ccs.neu.edu/research/gpc/VonaUtils/vona/terminal/vtansi.htm
-- http://www.termsys.demon.co.uk/vtansi.htm

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

-- get colorterm setting
--
-- COLORTERM: 8color/color8, 256color/color256, truecolor, nocolor
--
function tty._colorterm()
    local colorterm = tty._COLORTERM
    if colorterm == nil then
        colorterm = os.getenv("XMAKE_COLORTERM") or os.getenv("COLORTERM") or ""
        tty._COLORTERM = colorterm
    end
    return colorterm
end

-- erases from the current cursor position to the end of the current line.
function tty.erase_line_to_end()
    if tty.has_vtansi() then
        tty._iowrite("\x1b[K")
    end
    return tty
end

-- erases from the current cursor position to the start of the current line.
function tty.erase_line_to_start()
    if tty.has_vtansi() then
        tty._iowrite("\x1b[1K")
    end
    return tty
end

-- erases the entire current line
function tty.erase_line()
    if tty.has_vtansi() then
        tty._iowrite("\x1b[2K")
    end
    return tty
end

-- erases the screen from the current line down to the bottom of the screen.
function tty.erase_down()
    if tty.has_vtansi() then
        tty._iowrite("\x1b[J")
    end
    return tty
end

-- erases the screen from the current line up to the top of the screen.
function tty.erase_up()
    if tty.has_vtansi() then
        tty._iowrite("\x1b[1J")
    end
    return tty
end

-- erases the screen with the background colour and moves the cursor to home.
function tty.erase_screen()
    if tty.has_vtansi() then
        tty._iowrite("\x1b[2J")
    end
    return tty
end

-- save current cursor position.
function tty.cursor_save()
    if tty.has_vtansi() then
        tty._iowrite("\x1b[s")
    end
    return tty
end

-- restores cursor position after a save cursor.
function tty.cursor_restore()
    if tty.has_vtansi() then
        tty._iowrite("\x1b[u")
    end
    return tty
end

-- save current cursor position and color attrs
function tty.cursor_and_attrs_save()
    if tty.has_vtansi() then
        tty._iowrite("\x1b7")
    end
    return tty
end

-- restores cursor position and color attrs after a save cursor.
function tty.cursor_and_attrs_restore()
    if tty.has_vtansi() then
        tty._iowrite("\x1b8")
    end
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

-- get shell name
function tty.shell()
    local shell = tty._SHELL
    if shell == nil then
        local subhost = xmake._SUBHOST
        if subhost == "windows" then
            if os.getenv("PROMPT") then
                shell = "cmd"
            else
                local ok, result = os.iorun("pwsh -v")
                if ok then
                    shell = "pwsh"
                else
                    shell = "powershell"
                end
            end
        else
            shell = os.getenv("SHELL")
            if shell then
                for _, shellname in ipairs({"zsh", "bash", "sh"}) do
                    if shell:find(shellname) then
                        shell = shellname
                        break
                    end
                end
            end
        end
        tty._SHELL = shell or "sh"
    end
    return tty._SHELL
end

-- get terminal name
--  - xterm
--  - cmd
--  - vstudio (in visual studio)
--  - vscode (in vscode)
--  - msys2
--  - cygwin
--  - pwsh
--  - powershell
--  - mintty
--  - windows-terminal
--  - gnome-terminal
--  - xfce4-terminal
--  - konsole
--  - terminator
--  - rxvt
--  - lxterminal
--  - unknown
--
function tty.term()
    local term = tty._TERM
    if term == nil then

        -- get term from $TERM_PROGRAM
        if term == nil then
            local TERM_PROGRAM = os.getenv("TERM_PROGRAM")
            if TERM_PROGRAM ~= nil then
                if TERM_PROGRAM:find("vscode", 1, true) then
                    term = "vscode"
                elseif TERM_PROGRAM == "mintty" then
                    term = "mintty" -- git bash
                end
            end
        end

        -- get term from $TERM
        if term == nil then
            local TERM = os.getenv("TERM")
            if TERM ~= nil then
                if TERM:find("xterm", 1, true) then
                    term = "xterm"
                elseif TERM == "cygwin" then
                    term = "cygwin"
                end
            end
        end

        -- get term from system
        if term == nil then
            local subhost = xmake._SUBHOST
            if subhost == "windows" then
                if os.getenv("XMAKE_IN_VSTUDIO") then
                    term = "vstudio"
                elseif os.getenv("WT_SESSION") then
                    term = "windows-terminal"
                else
                    term = tty.shell()
                end
            elseif subhost == "msys" then
                term = "msys2"
            elseif subhost == "cygwin" then
                term = "cygwin"
            elseif subhost == "macosx" then
                term = "xterm"
            end
        end
        tty._TERM = term or "unknown"
    end
    return tty._TERM
end

-- has emoji?
function tty.has_emoji()
    local has_emoji = tty._HAS_EMOJI
    if has_emoji == nil then
        local term = tty.term()
        local winos = require("base/winos")

        -- before win8? disable it
        if has_emoji == nil and (os.host() == "windows" and winos.version():le("win8")) then
            has_emoji = false
        end

        -- on msys2/cygwin/powershell? disable it
        if has_emoji == nil and (term == "msys2" or term == "cygwin" or term == "powershell") then
            has_emoji = false
        end

        -- enable it by default
        if has_emoji == nil then
            has_emoji = true
        end
        tty._HAS_EMOJI = has_emoji or false
    end
    return has_emoji
end

-- has vtansi?
function tty.has_vtansi()
    return tty.has_color8()
end

-- has 8 colors?
function tty.has_color8()
    local has_color8 = tty._HAS_COLOR8
    if has_color8 == nil then

        -- detect it from $COLORTERM
        if has_color8 == nil then
            local colorterm = tty._colorterm()
            if colorterm == "nocolor" then
                has_color8 = false
            elseif colorterm and colorterm:find("8color", 1, true) then
                has_color8 = true
            elseif tty.has_color256() or tty.has_color24() then
                has_color8 = true
            end
        end

        -- detect it from $TERM
        local term = tty.term()
        if has_color8 == nil then
            if term == "vstudio" then
                has_color8 = false
            elseif term == "xterm" or term == "mintty" then
                has_color8 = true
            end
        end

        -- detect it from system
        if has_color8 == nil then
            if os.host() == "windows" then
                local winos = require("base/winos")
                if os.getenv("ANSICON") then
                    has_color8 = true
                elseif winos.version():le("win8") then
                    has_color8 = false
                else
                    has_color8 = true
                end
            else
                -- alway enabled for unix-like system
                has_color8 = true
            end
        end
        tty._HAS_COLOR8 = has_color8 or false
    end
    return has_color8
end

-- has 256 colors?
function tty.has_color256()

    local has_color256 = tty._HAS_COLOR256
    if has_color256 == nil then

        -- detect it from $COLORTERM
        if has_color256 == nil then
            local colorterm = tty._colorterm()
            if colorterm == "nocolor" then
                has_color256 = false
            elseif colorterm and (colorterm:find("256color", 1, true) or colorterm:find("color256", 1, true)) then
                has_color256 = true
            elseif tty.has_color24() then
                has_color256 = true
            end
        end

        -- detect it from $TERM
        local term = tty.term()
        local term_env = os.getenv("TERM")
        if has_color256 == nil then
            if term == "vstudio" then
                has_color256 = false
            elseif term_env and (term_env:find("256color", 1, true) or term_env:find("color256", 1, true)) then
                has_color256 = true
            end
        end

        -- detect it from system
        if has_color256 == nil then
            if os.host() == "windows" then
                has_color256 = false
            elseif os.host() == "linux" or os.host("macosx") then
                -- alway enabled for linux/macOS, $TERM maybe xterm, not xterm-256color, but it is supported
                has_color256 = true
            else
                has_color256 = false
            end
        end
        tty._HAS_COLOR256 = has_color256 or false
    end
    return has_color256
end

-- has 24bits true color?
--
-- There's no reliable way, and ncurses/terminfo's maintainer expressed he has no intent on introducing support.
-- S-Lang author added a check for $COLORTERM containing either "truecolor" or "24bit" (case sensitive).
-- In turn, VTE, Konsole and iTerm2 set this variable to "truecolor" (it's been there in VTE for a while,
-- it's relatively new and maybe still git-only in Konsole and iTerm2).
--
-- This is obviously not a reliable method, and is not forwarded via sudo, ssh etc. However, whenever it errs,
-- it errs on the safe side: does not advertise support whereas it's actually supported.
-- App developers can freely choose to check for this same variable, or introduce their own method
-- (e.g. an option in their config file), whichever matches better the overall design of the given app.
-- Checking $COLORTERM is recommended though, since that would lead to a more unique desktop experience
-- where the user has to set one variable only and it takes effect across all the apps, rather than something
-- separately for each app.
--
function tty.has_color24()

    local has_color24 = tty._HAS_COLOR24
    if has_color24 == nil then

        -- detect it from $COLORTERM
        if has_color24 == nil then
            local colorterm = tty._colorterm()
            if colorterm == "nocolor" then
                has_color24 = false
            elseif colorterm and (colorterm:find("truecolor", 1, true) or colorterm:find("24bit", 1, true)) then
                has_color24 = true
            end
        end

        -- detect it from $TERM
        local term = tty.term()
        local term_env = os.getenv("TERM")
        if has_color256 == nil then
            if term == "vstudio" then
                has_color256 = false
            elseif term_env and (term_env:find("truecolor", 1, true) or term_env:find("24bit", 1, true)) then
                has_color256 = true
            end
        end
        tty._HAS_COLOR24 = has_color24 or false
    end
    return has_color24
end

-- get term mode, e.g. stdin, stdout, stderr
--
-- local oldmode = tty.term_mode(stdtype)
-- local oldmode = tty.term_mode(stdtype, newmode)
--
function tty.term_mode(stdtype, newmode)
    local oldmode = 0
    if tty._term_mode then
        if stdtype == "stdin" then
            oldmode = tty._term_mode(1, newmode)
        elseif stdtype == "stdout" then
            oldmode = tty._term_mode(2, newmode)
        elseif stdtype == "stderr" then
            oldmode = tty._term_mode(3, newmode)
        end
    end
    return oldmode
end

-- return module
return tty
