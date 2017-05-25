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
-- @file        sudo.lua
--

-- imports
import("core.base.option")
import("detect.tool.find_sudo")

-- sudo run shell with administrator permission
--
-- .e.g
-- _sudo(os.run, "echo", "hello xmake!")
--
function _sudo(runner, cmd, ...)

    -- find sudo
    local program = find_sudo()
    assert(program, "sudo not found!")

    -- get current path environment
    local pathenv = os.getenv("PATH") 
    if pathenv and #pathenv > 0 then

        -- handle double quote
        pathenv = pathenv:gsub("\"", "\\\"")

        -- run it with administrator permission and preserve parent environment
        runner(program .. " PATH=\"" .. pathenv .. "\" " .. cmd, ...)
    else
        -- run it with administrator permission
        runner(program .. " " .. cmd, ...)
    end
end

-- sudo run shell with administrator permission and arguments list
--
-- .e.g
-- _sudov(os.runv, {"echo", "hello xmake!"})
--
function _sudov(runner, shellname, argv)

    -- find sudo
    local program = find_sudo()
    assert(program, "sudo not found!")

    -- run it with administrator permission and preserve parent environment
    runner(program, table.join("PATH=" .. os.getenv("PATH"), shellname, argv))
end

-- sudo run lua script with administrator permission and arguments list
--
-- .e.g
-- _lua(os.runv, "xxx.lua", {"arg1", "arg2"})
--
function _lua(runner, luafile, luaargv)

    -- init argv
    local argv = {"lua", "--root"}
    for _, name in ipairs({"file", "project", "backtrace", "verbose", "quiet"}) do
        local value = option.get(name)
        if type(value) == "string" then
            table.insert(argv, "--" .. name .. "=" .. value)
        elseif value then
            table.insert(argv, "--" .. name)
        end
    end
                  
    -- run it with administrator permission
    _sudov(runner, "xmake", table.join(argv, luafile, luaargv))
end

-- has sudo?
function has()
    return find_sudo() ~= nil
end

-- sudo run shell
function run(cmd, ...)
    return _sudo(os.run, cmd, ...)
end

-- sudo run shell with arguments list
function runv(shellname, argv)
    return _sudov(os.run, shellname, argv)
end

-- sudo quietly run shell and echo verbose info if [-v|--verbose] option is enabled
function vrun(cmd, ...)
    return _sudo(os.vrun, cmd, ...)
end

-- sudo quietly run shell with arguments list and echo verbose info if [-v|--verbose] option is enabled
function vrunv(shellname, argv)
    return _sudov(os.vrunv, shellname, argv)
end

-- sudo run shell and return output and error data
function iorun(cmd, ...)
    return _sudo(os.iorun, cmd, ...)
end

-- sudo run shell and return output and error data
function iorunv(shellname, argv)
    return _sudov(os.iorunv, shellname, argv)
end

-- sudo execute shell 
function exec(cmd, ...)
    return _sudo(os.exec, cmd, ...)
end

-- sudo execute shell with arguments list
function execv(shellname, argv)
    return _sudov(os.execv, shellname, argv)
end

-- sudo run lua script
function runl(luafile, luaargv)
    return _lua(os.runv, luafile, luaargv)
end

-- sudo quietly run lua script and echo verbose info if [-v|--verbose] option is enabled
function vrunl(luafile, luaargv)
    return _lua(os.vrunv, luafile, luaargv)
end

-- sudo run lua script and return output and error data
function iorunl(luafile, luaargv)
    return _lua(os.iorunv, luafile, luaargv)
end

-- sudo execute lua script 
function execl(luafile, luaargv)
    return _lua(os.execv, luafile, luaargv)
end
