import("core.base.scheduler")

function test_runjobs(t)

    local count = 0
    local task = function (a)
        t:are_equal(a, "xmake!")
        count = count + 1
    end
    for i = 1, 100 do
        scheduler.co_start(task, "xmake!")
    end
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
        if count == 3 then
            scheduler.stop()
        end
    end
    for i = 1, 3 do
        scheduler.co_start(task)
    end
    scheduler.runloop()
end

