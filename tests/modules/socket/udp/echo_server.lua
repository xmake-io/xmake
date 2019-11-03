import("core.base.socket")

function main()
    local sock = socket.udp()
    while true do 
        print("%s: recv ..", sock)
        local recv, data, addr, port = sock:recv(8192, {block = true})
        print("%s: recv: %d bytes from: %s:%d", sock, recv, addr, port)
        if data then
            data:dump()
        end
    end
    sock:close()
end
