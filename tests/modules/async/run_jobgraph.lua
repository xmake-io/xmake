import("core.base.scheduler")
import("async.jobgraph")
import("async.runjobs")

function _jobfunc(job, opt)
    print("%s: run job (%s)", scheduler.co_running(), job.name)
    local dt = os.mclock()
    os.sleep(1000)
    dt = os.mclock() - dt
    print("%s: run job (%s) end, progress: %s, dt: %d ms", scheduler.co_running(), job.name, opt.progress, dt)
end

function main()
    print("==================================== test jobpool ====================================")
    local jobs = jobgraph.new()
    jobs:add_job("job/root", _jobfunc)
    for i = 1, 3 do
        jobs:add_job("job/" .. i, _jobfunc)
        for j = 1, 50 do
            jobs:add_job("job/" .. i .. "/" .. j, _jobfunc)
        end
    end
    t = os.mclock()
    runjobs("test", jobs, {comax = 6, timeout = 1000, timer = function (running_jobs_indices)
        print("%s: timeout (%d ms), running: %s", scheduler.co_running(), os.mclock() - t, table.concat(running_jobs_indices, ","))
    end})
end

