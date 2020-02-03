import("core.base.scheduler")

function _session2(id)
    print("session2: %d ..", id)
    local dt = os.mclock()
    os.sleep(1000)
    dt = os.mclock() - dt
    print("session2: %d end, dt: %d ms", id, dt)
end

function _session1(id)
    print("session1: %d ..", id)
    local dt = os.mclock()
    scheduler.co_sleep(1000)
    dt = os.mclock() - dt
    print("session1: %d end, dt: %d ms", id, dt)
end

function main()
    for i = 1, 10 do
        scheduler.co_start(_session1, i)
        scheduler.co_start(_session2, i)
    end
end

