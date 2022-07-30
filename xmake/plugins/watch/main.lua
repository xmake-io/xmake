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
-- @file        main.lua
--

-- imports
import("core.base.option")
import("core.base.fwatcher")
import("core.project.config")

-- add watchdir
function _add_watchdir(watchdir, opt)
    opt = opt or {}
    cprint("watching ${bright}%s/%s${clear} ..", watchdir, opt.recursion and "**" or "*")
    fwatcher.add(watchdir, opt)
end

-- add watchdirs
function _add_watchdirs()
    local watchdirs = option.get("watchdirs")
    local plaindirs = option.get("plaindirs")
    if watchdirs or plaindirs then
        if watchdirs then
            for _, watchdir in ipairs(path.splitenv(watchdirs)) do
                for _, dir in ipairs(os.dirs(watchdir)) do
                    _add_watchdir(dir, {recursion = true})
                end
            end
        end
        if plaindirs then
            for _, watchdir in ipairs(path.splitenv(plaindirs)) do
                for _, dir in ipairs(os.dirs(watchdir)) do
                    _add_watchdir(dir)
                end
            end
        end
    elseif os.isfile(os.projectfile()) then
        watchdirs = os.dirs(path.join(os.projectdir(), "*|.*"))
        for _, watchdir in ipairs(watchdirs) do
            local buildir = path.absolute(config.buildir())
            if path.absolute(watchdir) ~= buildir then
                _add_watchdir(watchdir, {recursion = true})
            end
        end
        _add_watchdir(os.projectdir())
    else
        _add_watchdir(watchdir, {recursion = true})
    end
end

-- run command
function _run_command(events)
    try
    {
        function ()
            local commands = option.get("commands")
            local scriptfile = option.get("script")
            local arbitrary = option.get("arbitrary")
            if commands then
                for _, command in ipairs(commands:split(";")) do
                    os.exec(command)
                end
            elseif arbitrary then
                local program = arbitrary[1]
                local argv = #arbitrary > 1 and table.slice(arbitrary, 2) or {}
                os.execv(program, argv)
            elseif scriptfile and os.isfile(scriptfile) and path.extension(scriptfile) == ".lua" then
                local script = import(path.basename(scriptfile),
                    {rootdir = path.directory(scriptfile), anonymous = true})
                script(events)
            elseif os.isfile(os.projectfile()) then
                local argv = {"build", "-y"}
                if option.get("verbose") then
                    table.insert(argv, "-v")
                end
                if option.get("diagnosis") then
                    table.insert(argv, "-D")
                end
                if option.get("warning") then
                    table.insert(argv, "-w")
                end
                local target = option.get("target")
                if target then
                    table.insert(argv, target)
                end
                os.execv(os.programfile(), argv)
                if option.get("run") then
                    argv[1] = "run"
                    os.execv(os.programfile(), argv)
                end
            end
        end,
        catch
        {
            function (errors)
                cprint(tostring(errors))
            end
        }
    }
end

function main()

    -- add watchdirs
    _add_watchdirs()

    -- do watch
    local count = 0
    local events = {}
    while true do
        local ok, event = fwatcher.wait(300)
        if ok > 0 then
            local status
            if event.type == fwatcher.ET_CREATE then
                status = "created"
            elseif event.type == fwatcher.ET_MODIFY then
                status = "modified"
            elseif event.type == fwatcher.ET_DELETE then
                status = "deleted"
            end
            print(event.path, status)
            -- we use map to remove repeat events
            events[event.path .. tostring(event.type)] = event
            count = count + 1
        elseif count > 0 then
            _run_command(table.values(events))
            count = 0
        end
    end
end
