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

-- get the function key
function profiler:_func_key(funcinfo)
    local name = funcinfo.name or 'anonymous'
    local line = funcinfo.linedefined or 0
    local source = funcinfo.short_src or 'C_FUNC'
    return name .. source .. line
end

-- get the function title
function profiler:_func_title(funcinfo)
    local name = funcinfo.name or 'anonymous'
    local line = string.format("%d", funcinfo.linedefined or 0)
    local source = funcinfo.short_src or 'C_FUNC'
    if os.isfile(source) then
        source = path.relative(source, xmake._PROGRAM_DIR)
    end
    return string.format("%-30s: %s: %s", name, source, line)
end

-- get the function report
function profiler:_func_report(funcinfo)
    local key = self:_func_key(funcinfo)
    local report = self._REPORTS_BY_KEY[key]
    if not report then
        report =
        {
            funcinfo    = funcinfo
        ,   callcount   = 0
        ,   totaltime   = 0
        }
        self._REPORTS_BY_KEY[key] = report
        table.insert(self._REPORTS, report)
    end
    return report
end

-- profiling call
function profiler:_profiling_call(funcinfo)
    local report = self:_func_report(funcinfo)
    report.calltime    = os.clock()
    report.callcount   = report.callcount + 1
end

-- profiling return
function profiler:_profiling_return(funcinfo)
    local stoptime = os.clock()
    local report = self:_func_report(funcinfo)
    if report.calltime and report.calltime > 0 then
		report.totaltime = report.totaltime + (stoptime - report.calltime)
        report.calltime = 0
	end
end

-- the profiling handler
function profiler._profiling_handler(hooktype)
    local funcinfo = debug.getinfo(2, 'nS')
    if hooktype == "call" then
        profiler:_profiling_call(funcinfo)
    elseif hooktype == "return" then
        profiler:_profiling_return(funcinfo)
    end
end

-- the tracing handler
function profiler._tracing_handler(hooktype)
    local funcinfo = debug.getinfo(2, 'nS')
    if hooktype == "call" then
        local name = funcinfo.name
        local source = funcinfo.short_src
        if name and source and source:endswith(".lua") then
            local line = string.format("%d", funcinfo.linedefined or 0)
            utils.print("%-30s: %s: %s", name, source, line)
        end
    end
end

-- start profiling
function profiler:start()
    local mode = self:mode()
    if mode and mode == "trace" then
        debug.sethook(profiler._tracing_handler, 'cr', 0)
    else
        self._REPORTS        = self._REPORTS or {}
        self._REPORTS_BY_KEY = self._REPORTS_BY_KEY or {}
        self._STARTIME       = self._STARTIME or os.clock()
        debug.sethook(profiler._profiling_handler, 'cr', 0)
    end
end

-- stop profiling
function profiler:stop()

    -- trace?
    local mode = self:mode()
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
            utils.print("%6.3f, %6.2f%%, %7d, %s", report.totaltime, percent, report.callcount, self:_func_title(report.funcinfo))
        end
   end
end

-- get profiler mode, e.g. perf, trace
function profiler:mode()
    local mode = self._MODE
    if mode == nil then
        mode = os.getenv("XMAKE_PROFILE") or false
        self._MODE = mode
    end
    return mode or nil
end

-- profiler is enabled?
function profiler:enabled()
    local mode = self:mode()
    return mode ~= nil and (mode == "trace" or mode == "perf")
end

-- return module
return profiler
