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
-- @file        profiler.lua
--

-- define module
local profiler = {}

-- load modules
local os        = require("base/os")
local path      = require("base/path")
local table     = require("base/table")
local utils     = require("base/utils")
local string    = require("base/string")

-- get the function title
function profiler:_func_title(funcinfo)

    -- check
    assert(funcinfo)

    -- the function name
    local name = funcinfo.name or 'anonymous'

    -- the function line
    local line = string.format("%d", funcinfo.linedefined or 0)

    -- the function source
    local source = funcinfo.short_src or 'C_FUNC'
    if os.isfile(source) then
        source = path.relative(source, xmake._PROGRAM_DIR)
    end

    -- make title
    return string.format("%-30s: %s: %s", name, source, line)
end

-- get the function report
function profiler:_func_report(funcinfo)

    -- get the function title
    local title = self:_func_title(funcinfo)

    -- get the function report
    local report = self._REPORTS_BY_TITLE[title]
    if not report then

        -- init report
        report =
        {
            title       = self:_func_title(funcinfo)
        ,   callcount   = 0
        ,   totaltime   = 0
        }

        -- save it
        self._REPORTS_BY_TITLE[title] = report
        table.insert(self._REPORTS, report)
    end

    -- ok?
    return report
end

-- profiling call
function profiler:_profiling_call(funcinfo)

    -- get the function report
    local report = self:_func_report(funcinfo)
    assert(report)

    -- save the call time
    report.calltime    = os.clock()

    -- update the call count
    report.callcount   = report.callcount + 1

end

-- profiling return
function profiler:_profiling_return(funcinfo)

    -- get the stoptime
    local stoptime = os.clock()

    -- get the function report
    local report = self:_func_report(funcinfo)
    assert(report)

    -- update the total time
    if report.calltime and report.calltime > 0 then
		report.totaltime = report.totaltime + (stoptime - report.calltime)
        report.calltime = 0
	end
end

-- the profiling handler
function profiler._profiling_handler(hooktype)

    -- the function info
    local funcinfo = debug.getinfo(2, 'nS')

    -- dispatch it
    if hooktype == "call" then
        profiler:_profiling_call(funcinfo)
    elseif hooktype == "return" then
        profiler:_profiling_return(funcinfo)
    end
end

-- the tracing handler
function profiler._tracing_handler(hooktype)

    -- the function info
    local funcinfo = debug.getinfo(2, 'nS')

    -- is call?
    if hooktype == "call" then

        -- is xmake function?
        local name = funcinfo.name
        local source = funcinfo.short_src or 'C_FUNC'
        if name and os.isfile(source) then

            -- the function line
            local line = string.format("%d", funcinfo.linedefined or 0)

            -- get the relative source
            source = path.relative(source, xmake._PROGRAM_DIR)

            -- trace it
            utils.print("%-30s: %s: %s", name, source, line)
        end
    end
end

-- start profiling
function profiler:start(mode)

    -- trace?
    if mode and mode == "trace" then
        debug.sethook(profiler._tracing_handler, 'cr', 0)
    else
        -- init reports
        self._REPORTS           = {}
        self._REPORTS_BY_TITLE  = {}

        -- save the start time
        self._STARTIME = os.clock()

        -- start to hook
        debug.sethook(profiler._profiling_handler, 'cr', 0)
    end
end

-- stop profiling
function profiler:stop(mode)

    -- trace?
    if mode and mode == "trace" then

        -- stop to hook
        debug.sethook()

    else

        -- save the stop time
        self._STOPTIME = os.clock()

        -- stop to hook
        debug.sethook()

        -- calculate the total time
        local totaltime = self._STOPTIME - self._STARTIME

        -- sort reports
        table.sort(self._REPORTS, function(a, b)
            return a.totaltime > b.totaltime
        end)

        -- show reports
        for _, report in ipairs(self._REPORTS) do

            -- calculate percent
            local percent = (report.totaltime / totaltime) * 100
            if percent < 1 then
                break
            end

            -- trace
            utils.print("%6.3f, %6.2f%%, %7d, %s", report.totaltime, percent, report.callcount, report.title)
        end
   end
end

-- return module
return profiler
