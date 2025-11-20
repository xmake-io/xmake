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
-- Copyright (C) 2015-present, Xmake Open Source Community.
--
-- @author      ruki
-- @file        waiting_indicator.lua
--

-- imports
import("core.base.object")
import("core.base.tty")
import("core.theme.theme")

-- define module
local waiting_indicator = waiting_indicator or object { _init = { "_RUNNING", "_INDEX", "_STREAM", "_OPT" } }

-- stop the waiting indicator, clear written frames
function waiting_indicator:stop()
    if self._RUNNING ~= 0 then
        self:clear()
        self._RUNNING = 0
        self._INDEX = 0
    end
end

function waiting_indicator:_clear()
    if self._RUNNING == 1 then
        tty.erase_line_to_end()
        self._RUNNING = 2
        return true
    end
end

-- clear previous frame of the waiting indicator
function waiting_indicator:clear()
    if self:_clear() then
        self._STREAM:flush()
    end
end

-- write next frame of the waiting indicator
function waiting_indicator:write()
    local chars = self._OPT.chars[self._INDEX % #self._OPT.chars + 1]
    tty.cursor_and_attrs_save()
    self._STREAM:write(chars)
    self._STREAM:flush()
    tty.cursor_and_attrs_restore()
    self._INDEX = self._INDEX + 1
    self._RUNNING = 1
end

-- check if the waiting indicator is running
function waiting_indicator:running()
    return self._RUNNING and true or false
end

-- build a waiting indicator
-- @params stream - stream to write to, will use io.stdout if not provided
-- @params opt - options
--               - chars - an array of chars for waiting indicator
function new(stream, opt)
    stream = stream or io.stdout
    opt = opt or {}
    if opt.chars == nil or #opt.chars == 0 then
        opt.chars = theme.get("text.spinner.chars")
    end
    return waiting_indicator {_OPT = opt, _STREAM = stream, _RUNNING = 0, _INDEX = 0}
end

return {new = new}

