import("core.base.scheduler")
import("private.async.jobpool")
import("private.async.runjobs")

function _jobfunc(index, total)
    print("%s: run job (%d/%d)", scheduler.co_running(), index, total)
    local dt = os.mclock()
    os.sleep(1000)
    dt = os.mclock() - dt
    print("%s: run job (%d/%d) end, dt: %d ms", scheduler.co_running(), index, total, dt)
end

function main()

    -- test callback
    print("==================================== test callback ====================================")
    local t = os.mclock()
    runjobs("test", _jobfunc, {total = 100, comax = 6, timeout = 1000, timer = function (running_jobs_indices)
        print("%s: timeout (%d ms), running: %s", scheduler.co_running(), os.mclock() - t, table.concat(running_jobs_indices, ","))
    end})

    -- test jobs
    print("==================================== test jobs ====================================")
    local jobs = jobpool.new()
    local root = jobs:addjob("job/root", function (idx, total)
        _jobfunc(idx, total)
    end)
    for i = 1, 3 do
        local job = jobs:addjob("job/" .. i, function (idx, total)
            _jobfunc(idx, total)
        end, root)
        for j = 1, 50 do
            jobs:addjob("job/" .. i .. "/" .. j, function (idx, total)
                _jobfunc(idx, total)
            end, job)
        end
    end
    t = os.mclock()
    runjobs("test", jobs, {comax = 6, timeout = 1000, timer = function (running_jobs_indices)
        print("%s: timeout (%d ms), running: %s", scheduler.co_running(), os.mclock() - t, table.concat(running_jobs_indices, ","))
    end})
end

