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
    runjobs("test", _jobfunc, {total = 100, comax = 6, timeout = 1000, timer = function (running_jobs_indices)
        print("%s: timeout (%d ms), running: %s", scheduler.co_running(), os.mclock() - t, table.concat(running_jobs_indices, ","))
    end})
    printf("testing .. ")
    runjobs("test", function () 
        os.sleep(10000)
    end, {showtips = true})
    print("ok")
end

