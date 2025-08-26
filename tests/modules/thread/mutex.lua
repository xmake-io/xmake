import("core.thread.thread")
import("core.thread.mutex")

function callback(mutex)
    import("core.thread.thread")
    print("%s: starting ..", thread.running())
    local dt = os.mclock()
    for i = 1, 10 do
        mutex:lock()
        print("%s: %d", thread.running(), i)
        os.sleep(1000)
        mutex:unlock()
    end
    dt = os.mclock() - dt
    print("%s: end, dt: %d ms", thread.running(), dt)
end

function main()
    local m = mutex.new()
    local t0 = thread.start_named("thread_0", callback, m)
    local t1 = thread.start_named("thread_1", callback, m)
    t0:wait(-1)
    t1:wait(-1)
end

