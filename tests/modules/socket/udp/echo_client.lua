import("core.base.socket")

function main()
    local addr = "127.0.0.1"
    local port = 9001
    local sock = socket.udp()
    local send = sock:sendto("hello world..", addr, port, {block = true})
    print("%s: send to %s:%d %d bytes!", sock, addr, port, send)
    sock:close()
end
