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
-- @file        sudo.lua
--

-- imports
import("core.base.option")
import("detect.tools.find_sudo")

-- some inherited environment variables
function _envars(escape)
    local names  = {"PATH", "XMAKE_STATS", "COLORTERM"}
    local envars = {"env"}
    for _, name in ipairs(names) do
        local value = os.getenv(name)
        if escape and value then
            value = "\"" .. (value:gsub("\"", "\\\"")) .. "\""
        end
        table.insert(envars, name .. "=" .. (value or ""))
    end
    return envars
end

-- sudo run command with administrator permission
--
-- e.g.
-- _sudo(os.run, "echo", "hello xmake!")
--
function _sudo(runner, cmd, ...)

    -- find sudo
    local sudo = find_sudo()
    assert(sudo, "sudo not found!")

    -- run it with administrator permission and preserve parent environment
    runner(sudo .. " " .. table.concat(_envars(true), " ") .. " " .. cmd, ...)
end

-- sudo run command with administrator permission and arguments list
--
-- e.g.
-- _sudov(os.runv, {"echo", "hello xmake!"})
--
function _sudov(runner, program, argv, opt)

    -- find sudo
    local sudo = find_sudo()
    assert(sudo, "sudo not found!")

    -- run it with administrator permission and preserve parent environment
    runner(sudo, table.join(_envars(), program, argv), opt)
end

-- sudo run lua script with administrator permission and arguments list
--
-- e.g.
-- _lua(os.runv, "xxx.lua", {"arg1", "arg2"})
--
function _lua(runner, luafile, luaargv)

    -- init argv
    local argv = {"lua", "--root"}
    for _, name in ipairs({"file", "project", "diagnosis", "verbose", "quiet", "yes", "confirm"}) do
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

-- sudo run command
function run(cmd, ...)
    return _sudo(os.run, cmd, ...)
end

-- sudo run command with arguments list
function runv(program, argv, opt)
    return _sudov(os.run, program, argv, opt)
end

-- sudo quietly run command and echo verbose info if [-v|--verbose] option is enabled
function vrun(cmd, ...)
    return _sudo(os.vrun, cmd, ...)
end

-- sudo quietly run command with arguments list and echo verbose info if [-v|--verbose] option is enabled
function vrunv(program, argv, opt)
    return _sudov(os.vrunv, program, argv, opt)
end

-- sudo run command and return output and error data
function iorun(cmd, ...)
    return _sudo(os.iorun, cmd, ...)
end

-- sudo run command and return output and error data
function iorunv(program, argv, opt)
    return _sudov(os.iorunv, program, argv, opt)
end

-- sudo execute command
function exec(cmd, ...)
    return _sudo(os.exec, cmd, ...)
end

-- sudo execute command with arguments list
function execv(program, argv, opt)
    return _sudov(os.execv, program, argv, opt)
end

-- sudo run lua script
function runl(luafile, luaargv, opt)
    return _lua(os.runv, luafile, luaargv, opt)
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
