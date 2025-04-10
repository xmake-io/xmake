import("core.base.scheduler")
import("async.runjobs")

function _jobfunc(index, total, opt)
    print("%s: run job (%d/%d)", scheduler.co_running(), index, total)
    local dt = os.mclock()
    os.sleep(1000)
    dt = os.mclock() - dt
    print("%s: run job (%d/%d) end, progress: %s, dt: %d ms", scheduler.co_running(), index, total, opt.progress, dt)
end

function main()
    print("==================================== test callback ====================================")
    local t = os.mclock()
    runjobs("test", _jobfunc, {total = 100, comax = 6, timeout = 1000, timer = function (running_jobs_indices)
        print("%s: timeout (%d ms), running: %s", scheduler.co_running(), os.mclock() - t, table.concat(running_jobs_indices, ","))
    end})
end

