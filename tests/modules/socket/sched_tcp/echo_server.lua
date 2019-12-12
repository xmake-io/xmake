import("core.base.socket")
import("core.base.scheduler")

function _session(sock)
    local count = 0
    local result = nil
    while true do
        local recv, data = sock:recv(13, {block = true})
        if recv > 0 then
            result = data
            sock:send(data, {block = true})
            count = count + 1
        else
            break
        end
    end
    print("%s: recv: %d, count: %d", sock, result and result:size() or 0, count)
    result:dump()
    sock:close()
end

function _listen(addr, port)

    local sock = socket.bind(addr, port)
    sock:listen(20)
    print("%s: listening %s:%d ..", sock, addr, port) 
    while true do 
        local sock_client = sock:accept()
        if sock_client then
            print("%s: accepted", sock_client) 
            scheduler.co_start(_session, sock_client) 
        end
    end
    sock:close()
end

function main()
    scheduler.co_start(_listen, "127.0.0.1", 9001)
    scheduler.runloop()
end
