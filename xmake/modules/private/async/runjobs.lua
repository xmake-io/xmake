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

-- main entry
function main(name, jobfunc, total, comax, timeout, timerfunc)

    -- run timer
    local stop = false
    local running_jobs_indices
    if timerfunc then
        assert(timeout and timeout < 60000, "runjobs: invalid timer timeout!")
        scheduler.co_start_named(name .. "/timer", function ()
            while not stop do
                os.sleep(timeout)
                if not stop then
                    timerfunc(running_jobs_indices)
                end
            end
        end)
    end

    -- run jobs
    local index = 0
    local group_name = name
    comax = comax or total
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
end
