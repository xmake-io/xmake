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
-- @file        debugger.lua
--

-- define module
local debugger = {}

-- load modules
local os        = require("base/os")
local path      = require("base/path")

-- start emmylua debugger
--
-- e.g.
--
-- xrepo env -b emmylua_debugger xmake --version
--
function debugger:_start_emmylua_debugger()
    local debugger_libfile = os.getenv("EMMYLUA_DEBUGGER")
    local script, errors = package.loadlib(debugger_libfile, "luaopen_emmy_core")
    if not script then
        return false, errors
    end
    local debugger_inst = script()
    if not debugger_inst then
        return false, "cannot get debugger module!"
    end
    debugger_inst.tcpListen("localhost", 9966)
    debugger_inst.waitIDE()
    debugger_inst.breakHere()
    return true
end

-- start debugging
function debugger:start()
    if self:has_emmylua() then
        return self:_start_emmylua_debugger()
    end
end

-- has emmylua debugger?
function debugger:has_emmylua()
    local debugger_libfile = os.getenv("EMMYLUA_DEBUGGER")
    if debugger_libfile and os.isfile(debugger_libfile) then
        return true
    end
end

-- debugger is enabled?
function debugger:enabled()
    return self:has_emmylua()
end

-- return module
return debugger

