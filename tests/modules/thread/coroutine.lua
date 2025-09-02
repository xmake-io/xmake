import("core.base.thread")
import("core.base.scheduler")

function thread_loop()
    import("core.base.thread")
    print("%s: starting ..", thread.running())
    local dt = os.mclock()
    for i = 1, 10 do
        print("%s: %d", thread.running(), i)
        os.sleep(1000)
    end
    dt = os.mclock() - dt
    print("%s: end, dt: %d ms", thread.running(), dt)
end

function coroutine_loop()
    print("%s: starting ..", scheduler.co_running())
    local dt = os.mclock()
    for i = 1, 10 do
        print("%s: %d", scheduler.co_running(), i)
        os.sleep(1000)
    end
    dt = os.mclock() - dt
    print("%s: end, dt: %d ms", scheduler.co_running(), dt)
end

function main()
    scheduler.co_start_named("coroutine", coroutine_loop)
    local t = thread.start_named("thread", thread_loop)
    t:wait(-1)
end

