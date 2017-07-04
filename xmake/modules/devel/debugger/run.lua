--!The Make-like Build Utility based on Lua
--
-- Licensed to the Apache Software Foundation (ASF) under one
-- or more contributor license agreements.  See the NOTICE file
-- distributed with this work for additional information
-- regarding copyright ownership.  The ASF licenses this file
-- to you under the Apache License, Version 2.0 (the
-- "License"); you may not use this file except in compliance
-- with the License.  You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- 
-- Copyright (C) 2015 - 2017, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        run.lua
--

-- imports
import("core.base.option")
import("core.project.config")
import("detect.tools.find_gdb")
import("detect.tools.find_lldb")
import("detect.tools.find_windbg")
import("detect.tools.find_x64dbg")
import("detect.tools.find_ollydbg")
import("detect.tools.find_vsjitdebugger")

-- run gdb
function _run_gdb(program, argv)

    -- find gdb
    local gdb = find_gdb({program = config.get("debugger")})
    if not gdb then
        return false
    end

    -- patch arguments
    argv = argv or {}
    table.insert(argv, 1, program)
    table.insert(argv, 1, "--args")

    -- run it
    os.execv(gdb, argv)

    -- ok
    return true
end

-- run lldb
function _run_lldb(program, argv)

    -- find lldb
    local lldb = find_lldb({program = config.get("debugger")})
    if not lldb then
        return false
    end

    -- attempt to split name, .e.g xcrun -sdk macosx lldb 
    local names = lldb:split("%s")

    -- patch arguments
    argv = argv or {}
    table.insert(argv, 1, program)
    for i = #names, 2, -1 do
        table.insert(argv, 1, names[i])
    end

    -- run it
    os.execv(names[1], argv)

    -- ok
    return true
end

-- run windbg
function _run_windbg(program, argv)

    -- find windbg
    local windbg = find_windbg({program = config.get("debugger")})
    if not windbg then
        return false
    end

    -- patch arguments
    argv = argv or {}
    table.insert(argv, 1, program)

    -- run it
    os.execv(windbg, argv)

    -- ok
    return true
end

-- run x64dbg
function _run_x64dbg(program, argv)

    -- find x64dbg
    local x64dbg = find_x64dbg({program = config.get("debugger")})
    if not x64dbg then
        return false
    end

    -- patch arguments
    argv = argv or {}
    table.insert(argv, 1, program)

    -- run it
    os.execv(x64dbg, argv)

    -- ok
    return true
end

-- run ollydbg
function _run_ollydbg(program, argv)

    -- find ollydbg
    local ollydbg = find_ollydbg({program = config.get("debugger")})
    if not ollydbg then
        return false
    end

    -- patch arguments
    argv = argv or {}
    table.insert(argv, 1, program)

    -- run it
    os.execv(ollydbg, argv)

    -- ok
    return true
end

-- run vsjitdebugger
function _run_vsjitdebugger(program, argv)

    -- find vsjitdebugger
    local vsjitdebugger = find_vsjitdebugger({program = config.get("debugger")})
    if not vsjitdebugger then
        return false
    end

    -- patch arguments
    argv = argv or {}
    table.insert(argv, 1, program)

    -- run it
    os.execv(vsjitdebugger, argv)

    -- ok
    return true
end

-- run program with debugger
--
-- @param program   the program name
-- @param argv      the program rguments
--
-- @code
--
-- import("devel.debugger")
-- 
-- debugger.run("test")
-- debugger.run("echo", {"hello xmake!"})
--
-- @endcode
--
function main(program, argv)

    -- init debuggers
    local debuggers = 
    {
        {"lldb", _run_lldb}
    ,   {"gdb",  _run_gdb}
    }

    -- for windows target or on windows?
    if (config.plat() or os.host()) == "windows" then
        table.insert(debuggers, 1, {"windbg",           _run_windbg})
        table.insert(debuggers, 1, {"ollydbg",          _run_ollydbg})
        table.insert(debuggers, 1, {"x64dbg",           _run_x64dbg})
        table.insert(debuggers, 1, {"vsjitdebugger",    _run_vsjitdebugger})
    end

    -- get debugger from the configure
    local debugger = config.get("debugger")
    if debugger then
        debugger = debugger:lower()
        for _, _debugger in ipairs(debuggers) do
            if debugger:find(_debugger[1]) then
                if _debugger[2](program, argv) then
                    return 
                end
            end
        end
    else
        -- run debugger
        for _, _debugger in ipairs(debuggers) do
            if _debugger[2](program, argv) then
                return
            end
        end
    end

    -- no debugger
    raise("debugger not found!")
end
