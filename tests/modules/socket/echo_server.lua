import("core.base.socket")

function main()
    local sock = socket.bind("127.0.0.1", 9001)
    sock:listen(20)
    local sock_client = nil
    while true do 
        local ok = sock:wait(socket.EV_ACPT, -1)
        if ok == socket.EV_ACPT then
            sock_client = sock:accept()
            if sock_client then
                print(sock_client) 
                sock_client:close()
            end
        end
    end
    sock:close()
end
