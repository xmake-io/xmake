import("async.runjobs")

function test_run(total, comax)
    local f = function () end
    local t1 = os.mclock()
    runjobs("test", f, {total = total, comax = comax})
    t1 = os.mclock() - t1

    local n = total
    local t2 = os.mclock()
    while n ~= 0 do
        f()
        n = n - 1
    end
    t2 = os.mclock() - t2
    print("runjobs(%d/%d): %d ms, plain: %d ms", total, comax, t1, t2)
end

function test_run_proc(total, comax)
    local f = function () os.runv(os.programfile(), {"--version"}) end
    local t1 = os.mclock()
    runjobs("test", f, {total = total, comax = comax})
    t1 = os.mclock() - t1
    print("runjobs_proc(%d/%d): %d ms", total, comax, t1)
end

function main()
    test_run(10000, 1)
    test_run(10000, 10)
    test_run(10000, 100)
    test_run_proc(1000, 10)
end

