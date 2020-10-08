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
-- @file        event.lua
--

--[[ Console User Interface (cui) ]-----------------------------------------
Author: Tiago Dionizio (tiago.dionizio AT gmail.com)
$Id: event.lua 18 2007-06-21 20:43:52Z tngd $
--------------------------------------------------------------------------]]

-- load modules
local log    = require("ui/log")
local object = require("ui/object")

-- define module
local event = event or object { _init = {"type", "command", "extra"} }

-- register event types
function event:register(tag, ...)
    local base = self[tag] or 0
    local enums = {...}
    local n = #enums
    for i = 1, n do
        self[enums[i]] = i + base
    end
    self[tag] = base + n
end

-- is key?
function event:is_key(key_name)
    return self.type == event.ev_keyboard and self.key_name == key_name
end

-- is command event: cm_xxx?
function event:is_command(command)
    return self.type == event.ev_command and self.command == command
end

-- dump event
function event:dump()
    if self.type == event.ev_keyboard then
        log:print("event(key): %s %s ..", self.key_name, self.key_code)
    elseif self.type == event.ev_command then
        log:print("event(cmd): %s ..", self.command)
    else
        log:print("event(%s): ..", self.type)
    end
end

-- register event types, event.ev_keyboard = 1, event.ev_mouse = 2, ... , event.ev_idle = 5, event.ev_max = 5
event:register("ev_max", "ev_keyboard", "ev_mouse", "ev_command", "ev_text", "ev_idle")

-- register command event types (ev_command)
event:register("cm_max", "cm_quit", "cm_exit", "cm_enter")

-- define keyboard event
--
-- keyname = key name
-- keycode = key code
-- keymeta = ALT key was pressed
--
event.keyboard = object {_init = { "key_code", "key_name", "key_meta" }, type = event.ev_keyboard}

-- define mouse event
--
-- btn_name = button number and event type
-- btn_code = mouse event code
-- x, y = coordinates
--
event.mouse = object {_init = { "btn_code", "x", "y", "btn_name" }, type = event.ev_mouse}

-- define command event
event.command = object {_init = { "command", "extra" }, type = event.ev_command}

-- define idle event
event.idle = object {_init = {}, type = event.ev_idle}

-- return module
return event
