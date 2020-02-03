import("core.base.scheduler")

function test_runjobs(t)

    local count = 0
    local task = function (a)
        t:are_equal(a, "xmake!")
        count = count + 1
    end
    local cotasks = {}
    for i = 1, 100 do
        table.insert(cotasks, scheduler.co_start(task, "xmake!"))
    end
    scheduler.co_waitexit(cotasks)
    t:are_equal(count, 100)
end

function test_sleep(t)

    local count = 0
    local task = function (a)
        local dt = os.mclock()
        os.sleep(500)
        dt = os.mclock() - dt
        t:require(dt > 100 and dt < 1000)
        count = count + 1
    end
    for i = 1, 3 do
        scheduler.co_start(task)
    end
end

function test_yield(t)

    local count = 0
    local task = function (a)
        scheduler.co_yield()
        count = count + 1
    end
    local cotasks = {}
    for i = 1, 10 do
        table.insert(cotasks, scheduler.co_start(task))
    end
    scheduler.co_waitexit(cotasks)
    t:are_equal(count, 10)
end
