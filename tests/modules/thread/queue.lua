import("core.base.thread")

function callback(event, queue)
    import("core.base.thread")
    print("%s: starting ..", thread.running())
    while true do
        print("%s: waiting ..", thread.running())
        if event:wait(-1) > 0 then
            print("%s: triggered", thread.running())
        end
        while not queue:empty() do
            print("%s: get %s", thread.running(), queue:pop())
        end
    end
end

function main()
    local event = thread.event()
    local queue = thread.queue()
    local t = thread.start_named("keyboard", callback, event, queue)
    while true do
        local ch = io.read()
        if ch then
            queue:push(ch)
            event:post()
        end
    end
    t:wait(-1)
end

