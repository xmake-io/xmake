import("core.base.socket")

function main()
    local addr = "127.0.0.1"
    local port = 9001
    local sock = socket.bind(addr, port)
    sock:listen(20)
    local sock_client = nil
    while true do 
        print("%s: listening %s:%d ..", sock, addr, port) 
        local ok = sock:wait(socket.EV_ACPT, -1)
        if ok == socket.EV_ACPT then
            sock_client = sock:accept()
            if sock_client then
                print("%s: accepted", sock_client) 
                sock_client:close()
            end
        end
    end
    sock:close()
end
