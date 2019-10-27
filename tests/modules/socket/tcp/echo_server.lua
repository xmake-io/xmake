import("core.base.socket")

function main()

    local addr = "127.0.0.1"
    local port = 9001
    local sock = socket.bind(addr, port)
    sock:listen(20)
    print("%s: listening %s:%d ..", sock, addr, port) 
    while true do 
        local sock_client = sock:accept()
        if sock_client then
            print("%s: accepted", sock_client) 
            local recv, data = sock_client:recv(8192)
            print("%s: recv %d, data: %s", sock_client, recv, data or "")
            sock_client:close()
        end
    end
    sock:close()
end
