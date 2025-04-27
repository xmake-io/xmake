import("core.thread.thread")

function callback(id)
    print("import", import)
    --[[
    import("core.thread.thread")
    print("%s: %d starting ..", thread.running(), id)
    local dt = os.mclock()
    for i = 1, 10 do
        print("%s: %d", thread.running(), i)
        os.sleep(1000)
    end
    dt = os.mclock() - dt
    print("%s: %d end, dt: %d ms", thread.running(), id, dt)
    ]]
end

function main()
    local t0 = thread.start_named("thread_0", callback, 0)
    local t1 = thread.start_named("thread_1", callback, 1)
    t0:wait(-1)
    t1:wait(-1)
end

