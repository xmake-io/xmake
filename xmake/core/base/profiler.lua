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
local heap      = require("base/heap")
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
        report = {
            funcinfo    = funcinfo,
            callcount   = 0,
            totaltime   = 0
        }
        self._REPORTS_BY_KEY[key] = report
        table.insert(self._REPORTS, report)
    end
    return report
end

-- get the tag key
function profiler:_tag_key(name, argv)
    local key = name
    if argv then
        for _, item in ipairs(argv) do
            if type(item) == "table" then
                key = key .. os.args(item)
            else
                key = key .. tostring(item)
            end
        end
    end
    return key
end

-- get the tag title
function profiler:_tag_title(name, argv)
    local key = name
    if argv then
        for _, item in ipairs(argv) do
            if type(item) == "table" then
                key = key .. ": " .. os.args(item)
            else
                key = key .. ": " .. tostring(item)
            end
        end
    end
    return key
end

-- get the tag report
function profiler:_tag_report(name, argv)
    self._REPORTS_BY_KEY = self._REPORTS_BY_KEY or {}
    local key = self:_tag_key(name, argv)
    local report = self._REPORTS_BY_KEY[key]
    if not report then
        report = {
            name        = name,
            argv        = argv,
            callcount   = 0,
            totaltime   = 0
        }
        self._REPORTS_BY_KEY[key] = report
        self._REPORTS = self._REPORTS or {}
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
    if self:is_trace() then
        debug.sethook(profiler._tracing_handler, 'cr', 0)
    elseif self:is_perf("call") then
        self._REPORTS        = self._REPORTS or {}
        self._REPORTS_BY_KEY = self._REPORTS_BY_KEY or {}
        self._STARTIME       = self._STARTIME or os.clock()
        debug.sethook(profiler._profiling_handler, 'cr', 0)
    end
end

-- stop profiling
function profiler:stop()
    if self:is_trace() then
        debug.sethook()
    elseif self:is_perf("call") then
        self._STOPTIME = os.clock()
        debug.sethook()

        -- calculate the total time
        local totaltime = self._STOPTIME - self._STARTIME

        -- sort reports
        local reports = self._REPORTS or {}
        table.sort(reports, function(a, b)
            return a.totaltime > b.totaltime
        end)

        -- show reports
        for _, report in ipairs(reports) do
            local percent = (report.totaltime / totaltime) * 100
            if percent < 1 then
                break
            end
            utils.print("%6.3f, %6.2f%%, %7d, %s", report.totaltime, percent, report.callcount, self:_func_title(report.funcinfo))
        end
    elseif self:is_perf("tag") then

        -- sort reports, topN
        local reports = self._REPORTS or {}
        local h = heap.valueheap({cmp = function(a, b)
            return a.totaltime > b.totaltime
        end})
        for _, report in ipairs(reports) do
            h:push(report)
        end

        -- show reports
        local count = 0
        while count < 64 and h:length() > 0 do
            local report = h:pop()
            utils.print("%6.3f, %7d, %s", report.totaltime, report.callcount, self:_tag_title(report.name, report.argv))
            count = count + 1
        end
        if h:length() > 0 then
            utils.print("...")
        end
   end
end

-- enter the given tag for perf:tag
function profiler:enter(name, ...)
    local is_perf_tag = self._IS_PERF_TAG
    if is_perf_tag == nil then
        is_perf_tag = self:is_perf("tag")
        self._IS_PERF_TAG = is_perf_tag
    end
    if is_perf_tag then
        local argv = table.pack(...)
        local report = self:_tag_report(name, argv)
        report.calltime    = os.clock()
        report.callcount   = report.callcount + 1
    end
end

-- leave the given tag for perf:tag
function profiler:leave(name, ...)
    local is_perf_tag = self._IS_PERF_TAG
    if is_perf_tag == nil then
        is_perf_tag = self:is_perf("tag")
        self._IS_PERF_TAG = is_perf_tag
    end
    if is_perf_tag then
        local stoptime = os.clock()
        local argv = table.pack(...)
        local report = self:_tag_report(name, argv)
        if report.calltime and report.calltime > 0 then
            report.totaltime = report.totaltime + (stoptime - report.calltime)
            report.calltime = 0
        end
    end
end

-- get profiler mode, e.g. perf:call, perf:tag, perf:process, trace
function profiler:mode()
    local mode = self._MODE
    if mode == nil then
        mode = os.getenv("XMAKE_PROFILE") or false
        self._MODE = mode
    end
    return mode or nil
end

-- is trace?
function profiler:is_trace()
    local mode = self:mode()
    return mode and mode == "trace"
end

-- is perf?
function profiler:is_perf(name)
    local mode = self:mode()
    if mode and name then
        return mode == "perf:" .. name
    end
end

-- profiler is enabled?
function profiler:enabled()
    return self:is_perf("call") or self:is_perf("tag") or self:is_trace()
end

-- return module
return profiler
