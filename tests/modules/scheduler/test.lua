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


