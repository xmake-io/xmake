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
            local count = 0
            local result = nil
            while true do
                local recv, data = sock_client:recv(13, {block = true})
                if recv > 0 then
                    result = data
                    sock_client:send(data, {block = true})
                    count = count + 1
                else
                    break
                end
            end
            print("%s: recv: %d, count: %d", sock_client, result and result:size() or 0, count)
            result:dump()
            sock_client:close()
        end
    end
    sock:close()
end
