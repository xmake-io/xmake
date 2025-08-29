import("core.base.thread")

function callback(event, queue)
    print("starting ..")
    while true do
        print("waiting ..")
        if event:wait(-1) > 0 then
            while not queue:empty() do
                print("  -> %s", queue:pop())
            end
        end
    end
end

function main()
    local event = thread.event()
    local queue = thread.queue()
    local t = thread.start_named("", callback, event, queue)
    while true do
        local ch = io.read()
        if ch then
            queue:push(ch)
            event:post()
        end
    end
    t:wait(-1)
end

