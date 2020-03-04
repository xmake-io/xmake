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
import("core.base.hashset")

-- print back characters
function _print_backchars(backnum)
    if backnum > 0 then
        local str = ""
        for i = 1, backnum do
            str = str .. '\b'
        end
        for i = 1, backnum do
            str = str .. ' '
        end
        for i = 1, backnum do
            str = str .. '\b'
        end
        if #str > 0 then
            printf(str)
        end
    end
end

-- asynchronous run jobs 
function main(name, jobfunc, opt)

    -- init options
    op = opt or {}
    local total = opt.total or 1
    local comax = opt.comax or total
    local timeout = opt.timeout or 500
    local group_name = name
    assert(timeout < 60000, "runjobs: invalid timeout!")

    -- show waiting tips?
    local waitindex = 0
    local waitchars = opt.waitchars or {'\\', '-', '/', '|'}
    local backnum = 0
    local showtips = io.isatty() and opt.showtips -- we need hide wait characters if is not a tty

    -- run timer
    local stop = false
    local running_jobs_indices
    if opt.timer then
        scheduler.co_start_named(name .. "/timer", function ()
            while not stop do
                os.sleep(timeout)
                if not stop then
                    opt.timer(running_jobs_indices)
                end
            end
        end)
    elseif showtips then
        scheduler.co_start_named(name .. "/tips", function ()
            while not stop do
                os.sleep(timeout)
                if not stop then

                    -- print back characters
                    _print_backchars(backnum)

                    -- show waitchars
                    waitindex = ((waitindex + 1) % #waitchars)
                    local tips = nil
                    local waitobjs = scheduler.co_group_waitobjs(group_name)
                    if waitobjs:size() > 0 then
                        local names = {}
                        for _, obj in waitobjs:keys() do
                            if obj:otype() == scheduler.OT_PROC then
                                table.insert(names, obj:name())
                            elseif obj:otype() == scheduler.OT_SOCK then
                                table.insert(names, "sock")
                            elseif obj:otype() == scheduler.OT_PIPE then
                                table.insert(names, "pipe")
                            end
                        end
                        names = table.unique(names)
                        if #names > 0 then
                            names = table.concat(names, ",")
                            if #names > 16 then
                                names = names:sub(1, 16) .. ".."
                            end
                            tips = string.format("(%d/%s)", waitobjs:size(), names)
                        end
                    end
                    if tips then
                        cprintf("${dim}%s${clear} %s", tips, waitchars[waitindex + 1])
                        backnum = #tips + 2
                    else
                        printf(waitchars[waitindex + 1])
                        backnum = 1
                    end
                    io.flush()
                end
            end
        end)
    end

    -- run jobs
    local index = 0
    while index < total do
        running_jobs_indices = {}
        scheduler.co_group_begin(group_name, function ()
            local freemax = comax
            local co_group = scheduler.co_group(group_name)
            if co_group then
                freemax = freemax - #co_group
            end
            local max = math.min(index + freemax, total)
            while index < max do
                index = index + 1
                table.insert(running_jobs_indices, index)
                scheduler.co_start_named(name .. '/' .. tostring(index), function(i)
                    try
                    { 
                        function()
                            jobfunc(i)
                        end,
                        catch
                        {
                            function (errors)

                                -- stop timer and disable show waitchars first
                                stop = true

                                -- remove wait charactor
                                if showtips then
                                    _print_backchars(backnum)
                                    print("")
                                    io.flush()
                                end

                                -- do exit callback
                                if opt.exit then
                                    opt.exit(errors)
                                end

                                -- re-throw this errors and abort scheduler
                                raise(errors)
                            end
                        }
                    }
                end, index)
            end
        end)
    
        -- wait some jobs exited
        scheduler.co_group_wait(group_name, {limit = 1})
    end

    -- wait all jobs exited
    scheduler.co_group_wait(group_name)

    -- stop timer
    stop = true

    -- remove wait charactor
    if showtips then
        _print_backchars(backnum)
        io.flush()
    end

    -- do exit callback
    if opt.exit then
        opt.exit()
    end
end
