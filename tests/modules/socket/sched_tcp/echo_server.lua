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

function _listen(addr, port)

    local sock_clients = {}
    local sock = socket.bind(addr, port)
    sock:listen(100)
    print("%s: listening %s:%d ..", sock, addr, port)
    while true do
        local sock_client = sock:accept()
        if sock_client then
            print("%s: accepted", sock_client)
            table.insert(sock_clients, sock_client)
            scheduler.co_start(_session_recv, sock_client)
            scheduler.co_start(_session_send, sock_client)
        end
    end
    for _, sock_client in ipairs(sock_clients) do
        sock_client:close()
    end
    sock:close()
end

function main()
    scheduler.co_start(_listen, "127.0.0.1", 9001)
end
