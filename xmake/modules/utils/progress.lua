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
-- @author      OpportunityLiu
-- @file        progress.lua
--

-- imports
import("core.base.option")
import("core.base.object")
import("core.base.colors")
import("core.base.tty")
import("core.base.scheduler")
import("core.theme.theme")

-- define module
local progress = progress or object { _init = { "_RUNNING", "_INDEX", "_STREAM", "_OPT" } }

-- stop the progress indicator, clear written frames
function progress:stop()
    if self._RUNNING ~= 0 then
        self:clear()
        self._RUNNING = 0
        self._INDEX = 0
    end
end

function progress:_clear()
    if self._RUNNING == 1 then
        tty.erase_line_to_end()
        self._RUNNING = 2
        return true
    end
end

-- clear previous frame of the progress indicator
function progress:clear()
    if self:_clear() then
        self._STREAM:flush()
    end
end

-- write next frame of the progress indicator
function progress:write()
    local chars = self._OPT.chars[self._INDEX % #self._OPT.chars + 1]
    tty.cursor_and_attrs_save()
    self._STREAM:write(chars)
    self._STREAM:flush()
    tty.cursor_and_attrs_restore()
    self._INDEX = self._INDEX + 1
    self._RUNNING = 1
end

-- check if the progress indicator is running
function progress:running()
    return self._RUNNING and true or false
end

-- is scroll output?
function _is_scroll()
    local is_scroll = _g.is_scroll
    if is_scroll == nil then
        local style = theme.get("text.build.progress_style") or "scroll"
        if style == "scroll" then
            is_scroll = true
        end
        _g.is_scroll = is_scroll
    end
    return is_scroll
end

-- is multi-row refresh output?
function _is_multirow_refresh()
    local is_multirow_refresh = _g.is_multirow_refresh
    if is_multirow_refresh == nil then
        local style = theme.get("text.build.progress_style")
        if style == "multirow_refresh" and tty.has_vtansi() and io.isatty() then
            is_multirow_refresh = true
        end
        _g.is_multirow_refresh = is_multirow_refresh
    end
    return is_multirow_refresh
end

-- is single-row refresh output?
function _is_singlerow_refresh()
    local is_singlerow_refresh = _g.is_singlerow_refresh
    if is_singlerow_refresh == nil then
        local style = theme.get("text.build.progress_style")
        if style == "singlerow_refresh" and tty.has_vtansi() and io.isatty() then
            is_singlerow_refresh = true
        end
        _g.is_singlerow_refresh = is_singlerow_refresh
    end
    return is_singlerow_refresh
end

-- strip progress line
function _strip_progress_line(msg)
    local msg_plain = colors.translate(msg, {plain = true})
    local maxwidth = os.getwinsize().width
    if #msg_plain > maxwidth then
        -- windows width is too small? strip the partial message in middle
        local partlen = math.floor(maxwidth / 2) - 3
        local sep = msg_plain:sub(partlen + 1, #msg_plain - partlen - 1)
        local split = msg:split(sep, {plain = true, strict = true})
        msg = table.concat(split, "...")
    end
    return msg
end

-- show progress with verbose information
function _show_progress_with_verbose(progress, format, ...)
    local progress_prefix = "${color.build.progress}" .. theme.get("text.build.progress_format") .. ":${clear} "
    cprint(progress_prefix .. "${dim}" .. format, progress, ...)
end

-- show progress with scroll
function _show_progress_with_scroll(progress, format, ...)
    local progress_prefix = "${color.build.progress}" .. theme.get("text.build.progress_format") .. ":${clear} "
    cprint(progress_prefix .. format, progress, ...)
end

-- show progress with multi-row refresh
-- @see https://github.com/xmake-io/xmake/issues/6805
function _show_progress_with_multirow_refresh(progress, format, ...)
    local running = scheduler.co_running()
    if not running then
        _show_progress_with_scroll(progress, format, ...)
        return
    end

    -- get progress line
    local is_first = false
    local is_finished = math.floor(progress) == 100
    local progress_prefix = "${color.build.progress}" .. theme.get("text.build.progress_format") .. ":${clear} "
    local progress_msg = vformat(format, ...)
    local progress_line = _strip_progress_line(vformat(progress_prefix, progress) .. progress_msg)
    local progress_lineinfos = _g.progress_lineinfos
    if progress_lineinfos == nil then
        progress_lineinfos = {}
        _g.progress_lineinfos = progress_lineinfos
        tty.cursor_hide()
        is_first = true
    end

    -- update the progress info
    local linecount = _g.linecount or 0
    local lineinfo = progress_lineinfos[running]
    local current_time = os.mclock()
    if lineinfo == nil then
        _g.linecount = linecount + 1
        lineinfo = {start_time = current_time, spent_time = 0}
        progress_lineinfos[running] = lineinfo
    else
        lineinfo.spent_time = current_time - lineinfo.start_time
        lineinfo.start_time = current_time
    end
    local timecolor = ""
    local spent_time = lineinfo.spent_time
    if spent_time > 1000 then
        timecolor = "${magenta}"
    elseif spent_time > 500 then
        timecolor = "${yellow}"
    end
    local subprogress_line = _strip_progress_line(vformat("  ${dim}> %s%0.02fs${clear}${dim} ", timecolor, spent_time / 1000) .. progress_msg)
    lineinfo.progress_line = subprogress_line

    local maxwidth = os.getwinsize().width
    if not is_first and linecount > 0 then
        tty.cursor_move_to_col(maxwidth)
        tty.cursor_move_up(linecount + 1)
    end

    tty.erase_line_to_start().cr()
    cprint(progress_line)

    local lineinfos = {}
    for _, progress_lineinfo in pairs(progress_lineinfos) do
        table.insert(lineinfos, progress_lineinfo)
    end
    table.sort(lineinfos, function (a, b) return a.spent_time > b.spent_time end)
    for _, lineinfo in ipairs(lineinfos) do
        tty.cursor_move_to_col(maxwidth)
        tty.erase_line_to_start().cr()
        cprint(lineinfo.progress_line)
    end

    if is_finished then
        print("")
        _g.showing_without_scroll = false
        _g.progress_lineinfos = nil
        _g.linecount = 0
        tty.cursor_show()
    else
        _g.showing_without_scroll = true
    end
    io.flush()
end

-- show progress with single-row refresh (ninja style)
function _show_progress_with_singlerow_refresh(progress, format, ...)
    local is_finished = math.floor(progress) == 100
    local progress_prefix = "${color.build.progress}" .. theme.get("text.build.progress_format") .. ":${clear} "
    tty.erase_line_to_start().cr()
    cprintf(progress_prefix .. format, progress, ...)
    if is_finished then
        print("")
        _g.showing_without_scroll = false
    else
        _g.showing_without_scroll = true
    end
    io.flush()
end

-- showing progress line without scroll?
function showing_without_scroll()
    return _g.showing_without_scroll
end

-- show the message with progress
function show(progress, format, ...)
    progress = type(progress) == "table" and progress:percent() or math.floor(progress)
    local progress_prefix = "${color.build.progress}" .. theme.get("text.build.progress_format") .. ":${clear} "
    if option.get("verbose") then
        _show_progress_with_verbose(progress, format, ...)
    elseif _is_scroll() then
        _show_progress_with_scroll(progress, format, ...)
    elseif _is_multirow_refresh() then
        _show_progress_with_multirow_refresh(progress, format, ...)
    elseif _is_singlerow_refresh() then
        _show_progress_with_singlerow_refresh(progress, format, ...)
    else
        _show_progress_with_scroll(progress, format, ...)
    end
end

-- get the message text with progress
function text(progress, format, ...)
    progress = type(progress) == "table" and progress:percent() or math.floor(progress)
    local progress_prefix = "${color.build.progress}" .. theme.get("text.build.progress_format") .. ":${clear} "
    if option.get("verbose") then
        return string.format(progress_prefix .. "${dim}" .. format, progress, ...)
    else
        return string.format(progress_prefix .. format, progress, ...)
    end
end

-- build a progress indicator
-- @params stream - stream to write to, will use io.stdout if not provided
-- @params opt - options
--               - chars - an array of chars for progress indicator
function new(stream, opt)
    stream = stream or io.stdout
    opt = opt or {}
    if opt.chars == nil or #opt.chars == 0 then
        opt.chars = theme.get("text.spinner.chars")
    end
    return progress {_OPT = opt, _STREAM = stream, _RUNNING = 0, _INDEX = 0}
end
