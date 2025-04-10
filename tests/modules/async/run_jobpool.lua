import("core.base.scheduler")
import("private.async.jobpool")
import("async.runjobs")

function _jobfunc(index, total, opt)
    print("%s: run job (%d/%d)", scheduler.co_running(), index, total)
    local dt = os.mclock()
    os.sleep(1000)
    dt = os.mclock() - dt
    print("%s: run job (%d/%d) end, progress: %s, dt: %d ms", scheduler.co_running(), index, total, opt.progress, dt)
end

function main()
    print("==================================== test jobpool ====================================")
    local jobs = jobpool.new()
    local root = jobs:addjob("job/root", _jobfunc)
    for i = 1, 3 do
        local job = jobs:addjob("job/" .. i, _jobfunc, {rootjob = root})
        for j = 1, 50 do
            jobs:addjob("job/" .. i .. "/" .. j, _jobfunc, {rootjob = job})
        end
    end
    t = os.mclock()
    runjobs("test", jobs, {comax = 6, timeout = 1000, timer = function (running_jobs_indices)
        print("%s: timeout (%d ms), running: %s", scheduler.co_running(), os.mclock() - t, table.concat(running_jobs_indices, ","))
    end})
end

