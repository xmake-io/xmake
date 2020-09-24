import("core.base.socket")
import("core.base.scheduler")

function _session(sock, filepath)

    local file = io.open(filepath, 'rb')
    if file then
        local send = sock:sendfile(file, {block = true})
        print("%s: send %s %d bytes!", sock, filepath, send)
        file:close()
    end
    sock:close()
end

function _listen(addr, port, filepath)

    local sock = socket.bind(addr, port)
    sock:listen(100)
    print("%s: listening %s:%d ..", sock, addr, port)
    while true do
        local sock_client = sock:accept()
        if sock_client then
            print("%s: accepted", sock_client)
            scheduler.co_start(_session, sock_client, filepath)
        end
    end
    sock:close()
end

function main(filepath)
    scheduler.co_start(_listen, "127.0.0.1", 9090, filepath)
end
