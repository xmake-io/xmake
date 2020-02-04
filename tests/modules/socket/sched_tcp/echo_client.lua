import("core.base.socket")
import("core.base.scheduler")

function _session_recv(sock)
    print("%s: recv ..", sock)
    local count = 0
    local result = nil
    while count < 100000 do
        local recv, data = sock:recv(13, {block = true})
        if recv > 0 then
            result = data
            count = count + 1
        else
            break
        end
    end
    print("%s: recv ok, count: %d!", sock, count)
    if result then
        result:dump()
    end
end

function _session_send(sock)
    print("%s: send ..", sock)
    local count = 0
    while count < 100000 do
        local send = sock:send("hello world..", {block = true})
        if send > 0 then
            count = count + 1
        else
            break
        end
    end
    print("%s: send ok, count: %d!", sock, count)
end

local socks = {}
function _session(addr, port)

    print("connect %s:%d ..", addr, port)
    local sock = socket.connect(addr, port)
    if sock then
        print("%s: connected!", sock)
        table.insert(socks, sock)
        scheduler.co_group_begin("test", function ()
            scheduler.co_start(_session_recv, sock)
            scheduler.co_start(_session_send, sock)
        end)
    else
        print("connect %s:%d failed", addr, port)
    end
end

function main(count)
    count = count and tonumber(count) or 1
    scheduler.co_group_begin("test", function ()
        for i = 1, count do
            scheduler.co_start(_session, "127.0.0.1", 9001)
        end
    end)
    scheduler.co_group_wait("test")
    for _, sock in ipairs(socks) do
        sock:close()
    end
end
