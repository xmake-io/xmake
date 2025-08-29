import("core.base.thread")

function callback(event, sharedata)
    print("starting ..")
    while true do
        print("waiting ..")
        if event:wait(-1) > 0 then
            print("  -> %s", sharedata:get())
        end
    end
end

function main()
    local event = thread.event()
    local sharedata = thread.sharedata()
    local t = thread.start_named("", callback, event, sharedata)
    while true do
        local ch = io.read()
        if ch then
            sharedata:set(ch)
            event:post()
        end
    end
    t:wait(-1)
end

