import("core.base.socket")

function main()
    local sock = socket.connect("127.0.0.1", 9001)
    print(sock)
    sock:close()
end
