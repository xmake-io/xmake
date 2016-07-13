--!The Automatic Cross-platform Build Tool
-- 
-- XMake is free software; you can redistribute it and/or modify
-- it under the terms of the GNU Lesser General Public License as published by
-- the Free Software Foundation; either version 2.1 of the License, or
-- (at your option) any later version.
-- 
-- XMake is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU Lesser General Public License for more details.
-- 
-- You should have received a copy of the GNU Lesser General Public License
-- along with XMake; 
-- If not, see <a href="http://www.gnu.org/licenses/"> http://www.gnu.org/licenses/</a>
-- 
-- Copyright (C) 2015 - 2016, ruki All rights reserved.
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
    if report.calltime then
		report.totaltime = report.totaltime + (stoptime - report.calltime)
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
            utils.print("%04.3f, %5.2f%%, %7d, %s", report.totaltime, (report.totaltime / totaltime) * 100, report.callcount, report.title)
        end
   end
end

-- return module
return profiler
