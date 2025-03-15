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
import("lib.detect.find_tool")
import("private.utils.executable_path")
import("private.action.run.runenvs")

-- run gdb
function _run_gdb(program, argv, opt)
    opt = opt or {}
    local gdb = find_tool("gdb", {program = config.get("debugger")})
    if not gdb then
        return false
    end

    -- patch arguments
    argv = argv or {}
    table.insert(argv, 1, program)
    table.insert(argv, 1, "--args")

    -- run it
    os.execv(gdb.program, argv, table.join(opt, {exclusive = true}))
    return true
end

-- run cuda-gdb
function _run_cudagdb(program, argv, opt)
    opt = opt or {}
    local gdb = find_tool("cudagdb", {program = config.get("debugger")})
    if not gdb then
        return false
    end

    -- patch arguments
    argv = argv or {}
    table.insert(argv, 1, program)
    table.insert(argv, 1, "--args")

    -- run it
    os.execv(gdb.program, argv, table.join(opt, {exclusive = true}))
    return true
end

-- run lldb
function _run_lldb(program, argv, opt)
    opt = opt or {}
    local lldb = find_tool("lldb", {program = config.get("debugger")})
    if not lldb then
        return false
    end

    -- patch arguments
    argv = argv or {}
    table.insert(argv, 1, "--")
    table.insert(argv, 1, program)
    table.insert(argv, 1, "-f")

    -- run it
    os.execv(executable_path(lldb.program), argv, table.join(opt, {exclusive = true}))
    return true
end

-- run windbg
function _run_windbg(program, argv, opt)
    local windbg = find_tool("windbg", {program = config.get("debugger")})
    if not windbg then
        return false
    end

    -- patch arguments
    argv = argv or {}
    table.insert(argv, 1, program)

    -- run it
    opt.detach = true
    os.execv(windbg.program, argv, opt)
    return true
end

-- run cuda-memcheck
function _run_cudamemcheck(program, argv, opt)
    local cudamemcheck = find_tool("cudamemcheck", {program = config.get("debugger")})
    if not cudamemcheck then
        return false
    end

    -- patch arguments
    argv = argv or {}
    table.insert(argv, 1, program)

    -- run it
    os.execv(cudamemcheck.program, argv, opt)
    return true
end

-- run x64dbg
function _run_x64dbg(program, argv, opt)
    local x64dbg = find_tool("x64dbg", {program = config.get("debugger")})
    if not x64dbg then
        return false
    end

    -- patch arguments
    argv = argv or {}
    table.insert(argv, 1, program)

    -- run it
    opt.detach = true
    os.execv(x64dbg.program, argv, opt)
    return true
end

-- run ollydbg
function _run_ollydbg(program, argv, opt)
    local ollydbg = find_tool("ollydbg", {program = config.get("debugger")})
    if not ollydbg then
        return false
    end

    -- patch arguments
    argv = argv or {}
    table.insert(argv, 1, program)

    -- run it
    opt.detach = true
    os.execv(ollydbg.program, argv, opt)
    return true
end

-- run vsjitdebugger
function _run_vsjitdebugger(program, argv, opt)
    local vsjitdebugger = find_tool("vsjitdebugger", {program = config.get("debugger")})
    if not vsjitdebugger then
        return false
    end

    -- patch arguments
    argv = argv or {}
    table.insert(argv, 1, program)

    -- run it
    opt.detach = true
    os.execv(vsjitdebugger.program, argv, opt)
    return true
end

-- run devenv
function _run_devenv(program, argv, opt)
    local devenv = find_tool("devenv", {program = config.get("debugger")})
    if not devenv then
        return false
    end

    -- patch arguments
    argv = argv or {}
    table.insert(argv, 1, "/DebugExe")
    table.insert(argv, 2, program)

    -- run it
    opt.detach = true
    os.execv(devenv.program, argv, opt)
    return true
end

-- run renderdoc
function _run_renderdoc(program, argv, opt)
    local renderdoc = find_tool("renderdoc", {program = config.get("debugger")})
    if not renderdoc then
        return false
    end

    -- build capture settings
    local environment = {}
    if opt.addenvs then
        for name, values in pairs(opt.addenvs) do
            table.insert(environment, {
                separator = "Platform style",
                type = "Append",
                value = path.joinenv(values),
                variable = name
            })
        end
    end

    if opt.setenvs then
        for name, values in pairs(opt.setenvs) do
            table.insert(environment, {
                separator = "Platform style",
                type = "Set",
                value = path.joinenv(values),
                variable = name
            })
        end
    end

    local settings = {
        rdocCaptureSettings = 1,
        settings = {
            autoStart = false,
            commandLine = table.concat(table.wrap(argv), " "),
            environment = json.mark_as_array(environment),
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
    opt.addenvs = nil
    opt.setenvs = nil
    os.execv(renderdoc.program, { capturefile }, opt)
    return true
end

-- run gede
function _run_gede(program, argv, opt)
    opt = opt or {}

    -- 'gede --version' return with non-zero code
    local gede = find_tool("gede", {program = config.get("debugger"), norun = true})
    if not gede then
        return false
    end

    -- patch arguments
    argv = argv or {}
    table.insert(argv, 1, program)
    table.insert(argv, 1, "--args")
    table.insert(argv, 1, "--no-show-config")

    -- run it
    os.execv(gede.program, argv, table.join(opt, {exclusive = true}))
    return true
end

-- run seergdb
function _run_seergdb(program, argv, opt)
    opt = opt or {}
    local seergdb = find_tool("seergdb", {program = config.get("debugger")})
    if not seergdb then
        return false
    end

    -- patch arguments
    argv = argv or {}
    table.insert(argv, 1, program)
    table.insert(argv, 1, "--start")

    -- run it
    os.execv(seergdb.program, argv, table.join(opt, {exclusive = true}))
    return true
end

-- run rad debugger
function _run_raddbg(program, argv, opt)
    opt = opt or {}
    local raddbg = find_tool("raddbg", {program = config.get("debugger")})
    if not raddbg then
        return false
    end

    -- patch arguments
    argv = argv or {}
    table.insert(argv, 1, program)

    -- run it
    opt.detach = true
    os.execv(raddbg.program, argv, opt)
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
    ,   {"gede"        , _run_gede}
    ,   {"seergdb"     , _run_seergdb}
    }

    -- for windows target or on windows?
    if (config.plat() or os.host()) == "windows" then
        table.insert(debuggers, 1, {"windbg",           _run_windbg})
        table.insert(debuggers, 1, {"ollydbg",          _run_ollydbg})
        table.insert(debuggers, 1, {"x64dbg",           _run_x64dbg})
        table.insert(debuggers, 1, {"vsjitdebugger",    _run_vsjitdebugger})
        table.insert(debuggers, 1, {"devenv",           _run_devenv})
        table.insert(debuggers, 1, {"raddbg",           _run_raddbg})
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
