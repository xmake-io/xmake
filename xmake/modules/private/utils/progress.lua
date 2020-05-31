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
-- @author      OpportunityLiu
-- @file        progress.lua
--

-- imports
import("core.base.option")
import("core.base.object")
import("core.theme.theme")

-- make back characters
function _make_backchars(backnum)
    if backnum > 0 then
        return ('\b'):rep(backnum)
    end
    return ''
end

-- make clear characters
function _make_clearchars(backnum)
    if backnum > 0 then
        return ('\b'):rep(backnum) .. (' '):rep(backnum) .. ('\b'):rep(backnum)
    end
    return ''
end

-- define module
local process = process or object { _init = { "_RUNNING", "_INDEX", "_STREAM", "_OPT", "_CLEAR" } }

-- stop the progress indicator, clear written frames
function process:stop()
    if self._RUNNING ~= 0 then
        self:clear()
        self._RUNNING = 0
        self._INDEX = 0
    end
end

function process:_back()
    if self._RUNNING == 1 then
        self._STREAM:write(self._BACK)
        self._RUNNING = 2
        return true
    end
end

function process:_clear()
    if self._RUNNING == 1 then
        self._STREAM:write(self._CLEAR)
        self._RUNNING = 2
        return true
    end
end

-- clear previous frame of the progress indicator
function process:clear()
    if self:_clear() then
        self._STREAM:flush()
    end
end

-- write next frame of the progress indicator
function process:write()
    local chars = self._OPT.chars[self._INDEX % #self._OPT.chars + 1]
    self:_back()
    self._STREAM:write(chars)
    self._STREAM:flush()
    self._INDEX = self._INDEX + 1
    self._RUNNING = 1
end

-- check if the progress indicator is running
function process:running()
    return self._RUNNING and true or false
end

-- showing progress line without scroll?
function showing_without_scroll()
    return _g.showing_without_scroll
end

-- show the message with process
function show(progress, format, ...)
    local progress_prefix = "${color.build.progress}" .. theme.get("text.build.progress_format") .. ":${clear} "
    if option.get("verbose") then
        cprint(progress_prefix .. "${dim}" .. format, progress, ...)
    else
        local is_scroll = _g.is_scroll
        if is_scroll == nil then
            is_scroll = theme.get("text.build.progress_style") == "scroll"
            _g.is_scroll = is_scroll
        end
        if is_scroll then
            cprint(progress_prefix .. format, progress, ...)
        else
            utils.clearline()
            cprintf(progress_prefix .. format, progress, ...)
            if math.floor(progress) == 100 then
                print("")
                _g.showing_without_scroll = false
            else
                _g.showing_without_scroll = true
            end
            io.flush()
        end
    end
end

-- build a progress indicator
-- @params stream - stream to write to, will use io.stdout if not provided
-- @params opt - options
--               - chars - an array of chars for progress indicator
--               - width - width of progress indicator, will use #opt.chars[1] if not provided
function new(stream, opt)

    -- set default values
    stream = stream or io.stdout
    opt = opt or {}
    if opt.chars == nil or #opt.chars == 0 then
        opt.chars = theme.get("text.spinner.chars")
    end
    if opt.width == nil then
        -- only support one character now e.g. {'x', 'y', ..}
        -- TODO we need to get the display width of characters more accurately if support multi-characters, e.g. {"xx", "yy", ..}
        if is_subhost("windows") and #opt.chars[1] > 1 then -- is unicode character?
            opt.width = 2
        else
            opt.width = 1
        end
    end
    return process {_OPT = opt, _STREAM = stream, _RUNNING = 0, _INDEX = 0, _CLEAR = _make_clearchars(opt.width), _BACK = _make_backchars(opt.width)}
end
