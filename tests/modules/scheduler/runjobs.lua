import("core.base.scheduler")
import("private.async.runjobs")

function _jobfunc(index)
    print("%s: run job (%d)", scheduler.co_running(), index)
    local dt = os.mclock()
    os.sleep(1000)
    dt = os.mclock() - dt
    print("%s: run job (%d) end, dt: %d ms", scheduler.co_running(), index, dt)
end

function main()
    local t = os.mclock()
    runjobs("test", _jobfunc, 100, 6, 1000, function (running_jobs_indices)
        print("%s: timeout (%d ms), running: %s", scheduler.co_running(), os.mclock() - t, table.concat(running_jobs_indices, ","))
    end)
end

