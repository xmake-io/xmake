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
-- Copyright (C) 2015-2020, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        runjobs.lua
--

-- imports
import("core.base.scheduler")

-- asynchronous run jobs 
function main(name, jobfunc, opt)

    -- init options
    op = opt or {}
    local total = opt.total or 1
    local comax = opt.comax or total

    -- show waiting tips?
    local waitindex = 0
    local waitchars = opt.waitchars or {'\\', '-', '/', '|'}
    local showtips = io.isatty() and opt.showtips -- we need hide wait characters if is not a tty
    if showtips then
        printf(waitchars[waitindex + 1])
        io.flush()
    end

    -- run timer
    local stop = false
    local running_jobs_indices
    if opt.timer then
        assert(opt.timeout and opt.timeout < 60000, "runjobs: invalid timer timeout!")
        scheduler.co_start_named(name .. "/timer", function ()
            while not stop do
                os.sleep(opt.timeout)
                if not stop then
                    opt.timer(running_jobs_indices)
                end
            end
        end)
    elseif showtips then
        scheduler.co_start_named(name .. "/tips", function ()
            while not stop do
                os.sleep(opt.timeout or 300)
                if not stop then
                    waitindex = ((waitindex + 1) % #waitchars)
                    printf("\b" .. waitchars[waitindex + 1])
                    io.flush()
                end
            end
        end)
    end

    -- run jobs
    local index = 0
    local group_name = name
    while index < total do
        running_jobs_indices = {}
        scheduler.co_group_begin(group_name, function ()
            local max = math.min(index + comax, total)
            while index < max do
                index = index + 1
                table.insert(running_jobs_indices, index)
                scheduler.co_start_named(name .. '/' .. tostring(index), jobfunc, index)
            end
        end)
        scheduler.co_group_wait(group_name)
    end

    -- stop timer
    stop = true

    -- remove wait charactor
    if showtips then
        printf("\b")
        io.flush()
    end
end
