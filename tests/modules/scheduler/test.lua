import("core.base.scheduler")

function test_group(t)

    local count = 0
    local task = function (a)
        t:are_equal(a, "xmake!")
        count = count + 1
    end
    scheduler.co_group_begin("test", function ()
        for i = 1, 100 do
            scheduler.co_start(task, "xmake!")
        end
    end)
    scheduler.co_group_wait("test")
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
    scheduler.co_group_begin("test", function ()
        for i = 1, 10 do
            scheduler.co_start(task)
        end
    end)
    scheduler.co_group_wait("test")
    t:are_equal(count, 10)
end

function test_runjobs(t)
    import("private.async.runjobs")

    local total = 100
    local comax = 6
    local count = 0
    runjobs("test", function (index)
        t:require(index >= 1 and index <= total)
        count = count + 1
    end, {total = total, comax = comax})
    t:are_equal(count, total)
end
