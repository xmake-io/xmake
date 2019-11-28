import("core.base.socket")
import("core.base.scheduler")

function _session(addr, port)
    print("connect %s:%d ..", addr, port)
    local sock = socket.connect(addr, port)
    print("%s: connected!", sock)
    local count = 0
    while count < 10000 do
        local send = sock:send("hello world..", {block = true})
        if send > 0 then
            sock:recv(13, {block = true})
        else
            break
        end
        count = count + 1
    end
    print("%s: send ok, count: %d!", sock, count)
    sock:close()
end

function main(count)
    count = count and tonumber(count) or 1
    for i = 1, count do
        scheduler.run(_session, "127.0.0.1", 9001)
    end
    scheduler.runloop()
end
