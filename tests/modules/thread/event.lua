import("core.base.thread")

function callback(event)
    import("core.base.thread")
    print("%s: starting ..", thread.running())
    while true do
        print("%s: waiting ..", thread.running())
        if event:wait(-1) > 0 then
            print("%s: triggered", thread.running())
        end
    end
end

function main()
    local event = thread.event()
    local t = thread.start_named("keyboard", callback, event)
    while true do
        local ch = io.read()
        if ch then
            event:post()
        end
    end
    t:wait(-1)
end

