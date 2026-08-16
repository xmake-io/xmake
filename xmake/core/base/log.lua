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
--o
-- @author      ruki
-- @file        log.lua
--

-- define module: log
local log = log or {}

-- get the log file object
--
-- @return      the file object
--
function log:file()

    -- disable?
    if self._ENABLE ~= nil and not self._ENABLE then
        return
    end

    -- get the output file
    if self._FILE == nil then
        local outputfile = self:outputfile()
        if outputfile then

            -- get directory
            local i = outputfile:lastof("[/\\]")
            if i then
                if i > 1 then i = i - 1 end
                dir = outputfile:sub(1, i)
            else
                dir = "."
            end

            -- ensure the directory
            if not os.isdir(dir) then
                os.mkdir(dir)
            end

            -- open the log file in binary mode
            --
            -- 'w+' (text mode) translates '\n' to '\r\n' on Windows, which breaks
            -- downstream consumers (e.g. xmake-vscode's regex with a '$' anchor)
            -- because a trailing '\r' prevents the pattern from matching.
            self._FILE = io.open(outputfile, 'w+b')
        end
        self._FILE = self._FILE or false
    end
    return self._FILE
end

-- get the output log file path
--
-- @return      the log file path
--
function log:outputfile()
    if self._LOGFILE == nil then
        self._LOGFILE = os.getenv("XMAKE_LOGFILE") or false
    end
    return self._LOGFILE
end

-- clear the log file
function log:clear(state)
    if os.isfile(self:outputfile()) then
        io.writefile(self:outputfile(), "")
    end
end

-- enable or disable logging
--
-- @param state  true to enable, false to disable
--
function log:enable(state)
    self._ENABLE = state
end

-- flush log buffer to file
function log:flush()
    local file = self:file()
    if file then
        file:flush()
    end
end

-- close the log file
function log:close()
    local file = self:file()
    if file then
        file:close()
    end
end

-- print log with newline to the log file
--
-- @param ...   the format string and arguments
--
function log:print(...)
    local file = self:file()
    if file then
        file:write(string.format(...) .. "\n")
    end
end

-- print variables to the log file (verbose mode only)
--
-- @param ...   the variables to print
--
function log:printv(...)
    local file = self:file()
    if file then
        local values = {...}
        for i, v in ipairs(values) do
            -- dump basic type
            if type(v) == "string" or type(v) == "boolean" or type(v) == "number" then
                file:write(tostring(v))
            else
                file:write("<" .. tostring(v) .. ">")
            end
            if i ~= #values then
                file:write(" ")
            end
        end
        file:write('\n')
    end
end

-- printf log without newline to the log file
--
-- @param ...   the format string and arguments
--
function log:printf(...)
    local file = self:file()
    if file then
        file:write(string.format(...))
    end
end

-- write raw data to the log file
--
-- @param ...   the data to write
--
function log:write(...)
    local file = self:file()
    if file then
        file:write(...)
    end
end

-- return module: log
return log
