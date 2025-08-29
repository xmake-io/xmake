import("core.base.thread")

function callback(semaphore)
    import("core.base.thread")
    print("%s: starting ..", thread.running())
    while true do
        print("%s: waiting ..", thread.running())
        if semaphore:wait(-1) > 0 then
            print("%s: triggered", thread.running())
        end
    end
end

function main()
    local semaphore = thread.semaphore("", 1)
    local t = thread.start_named("keyboard", callback, semaphore)
    while true do
        local ch = io.read()
        if ch then
            semaphore:post(2)
        end
    end
    t:wait(-1)
end

