import("core.thread.thread")

function callback(id)
    print("%s: %d ..", thread.running(), id)
    local dt = os.mclock()
    os.sleep(1000)
    dt = os.mclock() - dt
    print("%s: %d end, dt: %d ms", thread.running(), id, dt)
end

function main()
    for i = 1, 10 do
        thread.start_named("thread_" .. i, callback, i)
    end
    --thread.wait()
end

