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
import("core.project.project")

-- define module
local progress = progress or object { _init = { "_RUNNING", "_INDEX", "_STREAM", "_OPT" } }

-- cache color strings
local COLOR_SUPERSLOW = "${color.build.progress_superslow}"
local COLOR_VERYSLOW = "${color.build.progress_veryslow}"
local COLOR_SLOW = "${color.build.progress_slow}"

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
        local style = project.policy("build.progress_style") or theme.get("text.build.progress_style") or "scroll"
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
        local style = project.policy("build.progress_style") or theme.get("text.build.progress_style")
        if style == "multirow" and tty.has_vtansi() and io.isatty() then
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
        local style = project.policy("build.progress_style") or theme.get("text.build.progress_style")
        if style == "singlerow" and tty.has_vtansi() and io.isatty() then
            is_singlerow_refresh = true
        end
        _g.is_singlerow_refresh = is_singlerow_refresh
    end
    return is_singlerow_refresh
end

-- get progress prefix
function _get_progress_prefix()
    if not _g.progress_prefix then
        _g.progress_prefix = "${color.build.progress}" .. theme.get("text.build.progress_format") .. ":${clear} "
    end
    return _g.progress_prefix
end

-- strip progress line
function _strip_progress_line(msg, maxwidth)
    local msg_plain = colors.translate(msg, {plain = true})
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
    cprint(_get_progress_prefix() .. "${dim}" .. format, progress, ...)
end

-- show progress with scroll
function _show_progress_with_scroll(progress, format, ...)
    cprint(_get_progress_prefix() .. format, progress, ...)
end

-- build ordered subprocess line infos from progress_lineinfos (internal helper)
function _build_ordered_subprocess_lineinfos(maxwidth, current_time)
    local progress_lineinfos = _g.progress_lineinfos
    if not progress_lineinfos then
        return {}
    end

    local order_lineinfos = {}
    for _, progress_lineinfo in pairs(progress_lineinfos) do
        local progress_msg = progress_lineinfo.progress_msg
        if progress_msg then
            local spent_time = current_time - progress_lineinfo.start_time
            local time_seconds = spent_time / 1000

            -- determine color based on time (use cached color constants)
            local timecolor
            if spent_time > 30000 then
                timecolor = COLOR_SUPERSLOW
            elseif spent_time > 1000 then
                timecolor = COLOR_VERYSLOW
            elseif spent_time > 500 then
                timecolor = COLOR_SLOW
            else
                timecolor = ""
            end

            progress_lineinfo.spent_time = spent_time
            -- use string.format instead of vformat for better performance
            local time_str = string.format("%s%0.02fs${clear} ", timecolor, time_seconds)
            local subprogress_line = _strip_progress_line("  > " .. time_str .. progress_msg, maxwidth)
            progress_lineinfo.progress_line = subprogress_line
            table.insert(order_lineinfos, progress_lineinfo)
        else
            progress_lineinfo.spent_time = 0
            progress_lineinfo.progress_line = nil
        end
    end

    table.sort(order_lineinfos, function (a, b) return a.spent_time > b.spent_time end)
    return order_lineinfos
end

-- display subprocess progress lines (internal helper)
function _display_subprocess_lines(order_lineinfos)
    local linecount = 0
    for _, lineinfo in ipairs(order_lineinfos) do
        -- we need not show it if the progress job is idle in runjobs now
        local progress_running = lineinfo.running
        if progress_running and progress_running:data("runjobs.running") == false then
            lineinfo.progress_line = nil
        end
        if lineinfo.progress_line then
            tty.erase_line().cr()
            cprint(lineinfo.progress_line)
            linecount = linecount + 1
        end
    end
    _g.linecount = linecount
end

-- redraw the multirow progress area (internal helper)
function _redraw_multirow_progress(maxwidth)
    local last_total_progress = _g.last_total_progress
    if not last_total_progress then
        return
    end

    -- redraw the total progress line
    tty.erase_line().cr()
    cprint(last_total_progress)

    -- build and display the subprocess lines
    local current_time = os.mclock()
    local order_lineinfos = _build_ordered_subprocess_lineinfos(maxwidth, current_time)
    _display_subprocess_lines(order_lineinfos)
    io.flush()
end

-- show progress with multi-row refresh
-- @see https://github.com/xmake-io/xmake/issues/6805
function _show_progress_with_multirow_refresh(progress, format, ...)
    local running = scheduler.co_running()
    if not running then
        _show_progress_with_scroll(progress, format, ...)
        return
    end

    -- get window size and time once
    local maxwidth = os.getwinsize().width
    local current_time = os.mclock()

    -- get progress line
    local is_first = false
    local is_finished = math.floor(progress) == 100
    local progress_msg = vformat(format, ...)
    local progress_line = _strip_progress_line(string.format(_get_progress_prefix(), progress) .. progress_msg, maxwidth)

    local progress_lineinfos = _g.progress_lineinfos
    if progress_lineinfos == nil then
        progress_lineinfos = {}
        _g.progress_lineinfos = progress_lineinfos
        is_first = true
    end
    if is_first then
        tty.cursor_hide()
        os.atexit(function (ok, errors)
            tty.cursor_show()
        end)
    end

    -- show the total progress line
    local linecount = _g.linecount or 0
    if not is_first and linecount > 0 then
        tty.cursor_move_up(linecount + 1)
    end
    tty.erase_line().cr()
    cprint(progress_line)

    -- save the total progress line and progress value for potential redraw in show_output
    _g.last_total_progress = progress_line
    _g.last_total_progress_value = progress

    -- update the current progress info
    local current_lineinfo = progress_lineinfos[running]
    if current_lineinfo == nil then
        current_lineinfo = {spent_time = 0, running = running}
        progress_lineinfos[running] = current_lineinfo
    end
    if is_finished then
        current_lineinfo.progress_msg = nil
    else
        current_lineinfo.progress_msg = progress_msg
        current_lineinfo.start_time = current_time
    end

    -- build and display the subprocess lines
    if not is_finished then
        local order_lineinfos = _build_ordered_subprocess_lineinfos(maxwidth, current_time)
        _display_subprocess_lines(order_lineinfos)
        _g.refresh_mode = "multirow"
    else
        -- when finished, clear all subprocess lines without leaving empty lines
        local old_linecount = _g.linecount or 0
        if old_linecount > 0 then
            tty.erase_down()
        end
        _g.refresh_mode = nil
        _g.progress_lineinfos = nil
        _g.last_total_progress = nil
        _g.last_total_progress_value = nil
        _g.linecount = 0
        tty.cursor_show()
    end
    io.flush()
end

-- show progress with single-row refresh (ninja style)
function _show_progress_with_singlerow_refresh(progress, format, ...)
    local maxwidth = os.getwinsize().width
    local is_finished = math.floor(progress) == 100
    local progress_msg = vformat(format, ...)
    local progress_line = _strip_progress_line(string.format(_get_progress_prefix(), progress) .. progress_msg, maxwidth)
    tty.erase_line().cr()
    cprintf(progress_line)
    if is_finished then
        print("")
        _g.refresh_mode = nil
    else
        _g.refresh_mode = "singlerow"
    end
    io.flush()
end

-- show the message with progress
function show(progress, format, ...)
    progress = type(progress) == "table" and progress:percent() or math.floor(progress)
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

-- print additional output logs with colors outside the progress log area, such as warning logs.
-- it's used when the progress style is multirow/singlerow refresh.
function show_output(format, ...)
    local refresh_mode = _g.refresh_mode
    if refresh_mode == "singlerow" then
        print("")
        cprint(format, ...)
    elseif refresh_mode == "multirow" then
        -- get window size once and the number of fixed progress lines at the bottom
        -- +1 for the total progress line
        local maxwidth = os.getwinsize().width
        local linecount = (_g.linecount or 0) + 1

        -- move to the top of progress area and clear to bottom
        tty.cursor_move_up(linecount)
        tty.erase_down()
        tty.cr()

        -- show the current task's progress line before the log output
        local progress_lineinfos = _g.progress_lineinfos
        if progress_lineinfos then
            local running = scheduler.co_running()
            if running then
                local current_lineinfo = progress_lineinfos[running]
                if current_lineinfo and current_lineinfo.progress_msg then
                    local progress_value = _g.last_total_progress_value or 0
                    local progress_line = _strip_progress_line(string.format(_get_progress_prefix(), math.floor(progress_value)) .. current_lineinfo.progress_msg, maxwidth)
                    tty.erase_line_to_end()
                    cprint(progress_line)
                end
            end
        end

        -- print the log output, which will scroll naturally
        cprint(format, ...)

        -- redraw the progress area immediately
        _redraw_multirow_progress(maxwidth)
    else
        cprint(format, ...)
    end
end

-- get the message text with progress
function text(progress, format, ...)
    progress = type(progress) == "table" and progress:percent() or math.floor(progress)
    local progress_prefix = _get_progress_prefix()
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
