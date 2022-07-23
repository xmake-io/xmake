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

-- get watchdirs
function _get_watchdirs()
    local results = {}
    local watchdirs = option.get("watchdirs")
    if watchdirs then
        for _, watchdir in ipairs(path.splitenv(watchdirs)) do
            local dirs = os.dirs(watchdir)
            if dirs then
                table.join2(results, dirs)
            end
        end
    elseif os.isfile(os.projectfile()) then
        watchdirs = os.dirs(path.join(os.projectdir(), "*|.*"))
        for _, watchdir in ipairs(watchdirs) do
            local buildir = path.absolute(config.buildir())
            if path.absolute(watchdir) ~= buildir then
                table.insert(results, watchdir)
            end
        end
    else
        table.insert(results, os.curdir())
    end
    return results
end

-- run command
function _run_command()
    if os.isfile(os.projectfile()) then
        os.execv(os.programfile(), {"build", "-w"})
    end
end

function main()

    -- get watchdirs
    local watchdirs = _get_watchdirs()
    if #watchdirs > 0 then
        for _, watchdir in ipairs(watchdirs) do
            cprint("watching ${bright}%s${clear} ..", watchdir)
        end
    else
        raise("no any watch directories!")
    end

    -- do watch
    fwatcher.watchdirs(watchdirs, function (event)
        local status
        if event.type == fwatcher.ET_CREATE then
            status = "created"
        elseif event.type == fwatcher.ET_MODIFY then
            status = "modified"
        elseif event.type == fwatcher.ET_DELETE then
            status = "deleted"
        end
        print(event.path, status)

        -- run command
        _run_command()

    end, {recursion = option.get("recursion")})
end
