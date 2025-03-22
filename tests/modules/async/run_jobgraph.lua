import("core.base.scheduler")
import("async.jobgraph")
import("async.runjobs")

function _jobfunc(index, total, opt)
    print("%s: run job (%d/%d)", scheduler.co_running(), index, total)
    local dt = os.mclock()
    os.sleep(1000)
    dt = os.mclock() - dt
    print("%s: run job (%d/%d) end, progress: %s, dt: %d ms", scheduler.co_running(), index, total, opt.progress, dt)
end

function _test_basic()
    print("==================================== test basic ====================================")
    local jobs = jobgraph.new()
    jobs:add("job/root", _jobfunc)
    for i = 1, 3 do
        jobs:add("job/" .. i, _jobfunc)
        for j = 1, 50 do
            jobs:add("job/" .. i .. "/" .. j, _jobfunc)
            jobs:add_deps("job/" .. i .. "/" .. j, "job/" .. i, "job/root")
        end
    end
    t = os.mclock()
    runjobs("test", jobs, {comax = 6, timeout = 1000, timer = function (running_jobs_indices)
        print("%s: timeout (%d ms), running: %s", scheduler.co_running(), os.mclock() - t, table.concat(running_jobs_indices, ","))
    end})
end

function _test_group()
    print("==================================== test group ====================================")
    local jobs = jobgraph.new()
    jobs:add("job/root", _jobfunc)
    for i = 1, 3 do
        jobs:add("job/" .. i, _jobfunc, {groups = "bar"})
        for j = 1, 50 do
            jobs:add("job/" .. i .. "/" .. j, _jobfunc, {groups = "foo"})
        end
    end
    jobs:add_deps("foo", "bar", "job/root")
    t = os.mclock()
    runjobs("test", jobs, {comax = 6, timeout = 1000, timer = function (running_jobs_indices)
        print("%s: timeout (%d ms), running: %s", scheduler.co_running(), os.mclock() - t, table.concat(running_jobs_indices, ","))
    end})
end

function main()
    _test_basic()
    _test_group()
end

