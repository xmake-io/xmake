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
-- @file        application.lua
--

-- load modules
local os        = require("base/os")
local utils     = require("base/utils")
local log       = require("ui/log")
local rect      = require("ui/rect")
local event     = require("ui/event")
local curses    = require("ui/curses")
local program   = require("ui/program")
local desktop   = require("ui/desktop")
local menubar   = require("ui/menubar")
local statusbar = require("ui/statusbar")

-- define module
local application = application or program()

-- init application
function application:init(name, argv)

    -- init log
    log:clear()
--    log:enable(false)

    -- trace
    log:print("<application: %s>: init ..", name)

    -- init program
    program.init(self, name, argv)

    -- trace
    log:print("<application: %s>: init ok", name)
end

-- exit application
function application:exit()

    -- exit program
    program.exit(self)

    -- flush log
    log:flush()
end

-- get menubar
function application:menubar()
    if not self._MENUBAR then
        self._MENUBAR = menubar:new("menubar", rect{0, 0, self:width(), 1})
    end
    return self._MENUBAR
end

-- get desktop
function application:desktop()
    if not self._DESKTOP then
        self._DESKTOP = desktop:new("desktop", rect{0, 1, self:width(), self:height() - 1})
    end
    return self._DESKTOP
end

-- get statusbar
function application:statusbar()
    if not self._STATUSBAR then
        self._STATUSBAR = statusbar:new("statusbar", rect{0, self:height() - 1, self:width(), self:height()})
    end
    return self._STATUSBAR
end

-- on event
function application:on_event(e)
    program.on_event(self, e)
end

-- on resize
function application:on_resize()
    self:menubar():bounds_set(rect{0, 0, self:width(), 1})
    self:desktop():bounds_set(rect{0, 1, self:width(), self:height() - 1})
    self:statusbar():bounds_set(rect{0, self:height() - 1, self:width(), self:height()})
    program.on_resize(self)
end

-- run application
function application:run(...)

    -- init runner
    local argv = {...}
    local runner = function ()

        -- new an application
        local app = self:new(argv)
        if app then
            app:loop()
            app:exit()
        end
    end

    -- run application
    local ok, errors = utils.trycall(runner)

    -- exit curses
    if not ok then
        if not curses.isdone() then
            curses.done()
        end
        log:flush()
        os.raise(errors)
    end
end

-- return module
return application
