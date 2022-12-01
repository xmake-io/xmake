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
-- @file        run.lua
--

-- imports
import("core.base.json")
import("core.base.option")
import("core.project.config")
import("detect.tools.find_cudagdb")
import("detect.tools.find_cudamemcheck")
import("detect.tools.find_gdb")
import("detect.tools.find_lldb")
import("detect.tools.find_windbg")
import("detect.tools.find_x64dbg")
import("detect.tools.find_ollydbg")
import("detect.tools.find_devenv")
import("detect.tools.find_vsjitdebugger")
import("detect.tools.find_renderdoc")

-- run gdb
function _run_gdb(program, argv, opt)

    -- find gdb
    opt = opt or {}
    local gdb = find_gdb({program = config.get("debugger")})
    if not gdb then
        return false
    end

    -- patch arguments
    argv = argv or {}
    table.insert(argv, 1, program)
    table.insert(argv, 1, "--args")

    -- run it
    os.execv(gdb, argv, table.join(opt, {exclusive = true}))
    return true
end

-- run cuda-gdb
function _run_cudagdb(program, argv, opt)

    -- find cudagdb
    opt = opt or {}
    local gdb = find_cudagdb({program = config.get("debugger")})
    if not gdb then
        return false
    end

    -- patch arguments
    argv = argv or {}
    table.insert(argv, 1, program)
    table.insert(argv, 1, "--args")

    -- run it
    os.execv(gdb, argv, table.join(opt, {exclusive = true}))
    return true
end

-- run lldb
function _run_lldb(program, argv, opt)

    -- find lldb
    opt = opt or {}
    local lldb = find_lldb({program = config.get("debugger")})
    if not lldb then
        return false
    end

    -- attempt to split name, e.g. xcrun -sdk macosx lldb
    local names = lldb:split("%s")

    -- patch arguments
    argv = argv or {}
    table.insert(argv, 1, "--")
    table.insert(argv, 1, program)
    table.insert(argv, 1, "-f")
    for i = #names, 2, -1 do
        table.insert(argv, 1, names[i])
    end

    -- run it
    os.execv(names[1], argv, table.join(opt, {exclusive = true}))
    return true
end

-- run windbg
function _run_windbg(program, argv, opt)

    -- find windbg
    local windbg = find_windbg({program = config.get("debugger")})
    if not windbg then
        return false
    end

    -- patch arguments
    argv = argv or {}
    table.insert(argv, 1, program)

    -- run it
    opt.detach = true
    os.execv(windbg, argv, opt)
    return true
end

-- run cuda-memcheck
function _run_cudamemcheck(program, argv, opt)

    -- find cudamemcheck
    local cudamemcheck = find_cudamemcheck({program = config.get("debugger")})
    if not cudamemcheck then
        return false
    end

    -- patch arguments
    argv = argv or {}
    table.insert(argv, 1, program)

    -- run it
    os.execv(cudamemcheck, argv, opt)
    return true
end

-- run x64dbg
function _run_x64dbg(program, argv, opt)

    -- find x64dbg
    local x64dbg = find_x64dbg({program = config.get("debugger")})
    if not x64dbg then
        return false
    end

    -- patch arguments
    argv = argv or {}
    table.insert(argv, 1, program)

    -- run it
    opt.detach = true
    os.execv(x64dbg, argv, opt)
    return true
end

-- run ollydbg
function _run_ollydbg(program, argv, opt)

    -- find ollydbg
    local ollydbg = find_ollydbg({program = config.get("debugger")})
    if not ollydbg then
        return false
    end

    -- patch arguments
    argv = argv or {}
    table.insert(argv, 1, program)

    -- run it
    opt.detach = true
    os.execv(ollydbg, argv, opt)
    return true
end

-- run vsjitdebugger
function _run_vsjitdebugger(program, argv, opt)

    -- find vsjitdebugger
    local vsjitdebugger = find_vsjitdebugger({program = config.get("debugger")})
    if not vsjitdebugger then
        return false
    end

    -- patch arguments
    argv = argv or {}
    table.insert(argv, 1, program)

    -- run it
    opt.detach = true
    os.execv(vsjitdebugger, argv, opt)
    return true
end

-- run devenv
function _run_devenv(program, argv, opt)

    -- find devenv
    local devenv = find_devenv({program = config.get("debugger")})
    if not devenv then
        return false
    end

    -- patch arguments
    argv = argv or {}
    table.insert(argv, 1, "/DebugExe")
    table.insert(argv, 2, program)

    -- run it
    opt.detach = true
    os.execv(devenv, argv, opt)
    return true
end

-- run renderdoc
function _run_renderdoc(program, argv, opt)

    -- find renderdoc
    local renderdoc = find_renderdoc({program = config.get("debugger")})
    if not renderdoc then
        return false
    end

    -- build capture settings
    local settings = {
        rdocCaptureSettings = 1,
        settings = {
            autoStart = false,
            commandLine = table.concat(table.wrap(argv), " "),
            environment = json.mark_as_array({}),
            executable = program,
            inject = false,
            numQueuedFrames = 0,
            queuedFrameCap = 0,
            workingDir = opt.curdir and path.absolute(opt.curdir) or "",
            options = {
                allowFullscreen = true,
                allowVSync = true,
                apiValidation = false,
                captureAllCmdLists = false,
                captureCallstacks = false,
                captureCallstacksOnlyDraws = false,
                debugOutputMute = true,
                delayForDebugger = 0,
                hookIntoChildren = false,
                refAllResources = false,
                verifyBufferAccess = false
            }
        }
    }

    -- save to temporary file
    local capturefile = os.tmpfile() .. ".cap"
    json.savefile(capturefile, settings)

    -- run renderdoc
    opt.detach = true
    os.execv(renderdoc, { capturefile }, opt)
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
function main(program, argv, opt)

    -- init debuggers
    local debuggers =
    {
        {"lldb"        , _run_lldb}
    ,   {"gdb"         , _run_gdb}
    ,   {"cudagdb"     , _run_cudagdb}
    ,   {"cudamemcheck", _run_cudamemcheck}
    ,   {"renderdoc"   , _run_renderdoc}
    }

    -- for windows target or on windows?
    if (config.plat() or os.host()) == "windows" then
        table.insert(debuggers, 1, {"windbg",           _run_windbg})
        table.insert(debuggers, 1, {"ollydbg",          _run_ollydbg})
        table.insert(debuggers, 1, {"x64dbg",           _run_x64dbg})
        table.insert(debuggers, 1, {"vsjitdebugger",    _run_vsjitdebugger})
        table.insert(debuggers, 1, {"devenv",           _run_devenv})
    end

    -- get debugger from configuration
    opt = opt or {}
    local debugger = config.get("debugger")
    if debugger then

        -- try exactmatch first
        debugger = debugger:lower()
        local debuggername = path.basename(debugger)
        for _, _debugger in ipairs(debuggers) do
            if debuggername:startswith(_debugger[1]) then
                if _debugger[2](program, argv, opt) then
                    return
                end
            end
        end

        for _, _debugger in ipairs(debuggers) do
            if debugger:find(_debugger[1]) then
                if _debugger[2](program, argv, opt) then
                    return
                end
            end
        end
    else
        -- run debugger
        for _, _debugger in ipairs(debuggers) do
            if _debugger[2](program, argv, opt) then
                return
            end
        end
    end

    -- no debugger
    raise("debugger%s not found!", debugger and ("(" .. debugger .. ")") or "")
end
