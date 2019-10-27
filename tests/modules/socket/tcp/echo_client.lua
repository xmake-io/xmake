import("core.base.socket")

function main()
    local addr = "127.0.0.1"
    local port = 9001
    print("connect %s:%d ..", addr, port)
    local sock = socket.connect(addr, port)
    print("%s: connected!", sock)
    local send = sock:send("hello")
    print("%s: send %d", sock, send)
    sock:close()
end
