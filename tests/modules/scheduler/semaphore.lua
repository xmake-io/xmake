import("core.base.scheduler")

function _loop(semaphore, id)
    print("[%d]: start", id)
    while true do
        print("[%d]: wait ..", id)
        --semaphore:wait(-1)
        os.sleep(1000)
    end
    print("[%d]: end", id)
end

function _input(semaphore)
    while true do
        if io.readable() then
            local ch = io.read()
            print("  -> post semaphore")
            if ch then
                semaphore:post(2)
            end
        else
            os.sleep(1000)
        end
    end
end

function main()
    local semaphore = scheduler.co_semaphore("", 1)
    for i = 1, 10 do
        scheduler.co_start(_loop, semaphore, i)
    end
    scheduler.co_start(_input, semaphore)
end

