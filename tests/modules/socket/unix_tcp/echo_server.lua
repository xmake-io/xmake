import("core.base.bytes")
import("core.base.socket")

function main(addr)

    addr = addr or path.join(os.tmpdir(), "echo.socket")
    os.tryrm(addr)
    local sock = socket.bind_unix(addr)
    sock:listen(20)
    print("%s: listening %s ..", sock, addr)
    while true do
        local sock_client = sock:accept()
        if sock_client then
            print("%s: accepted", sock_client)
            local count = 0
            local result = nil
            local buff = bytes(8192)
            while true do
                local recv, data = sock_client:recv(buff, 13, {block = true})
                if recv > 0 then
                    result = data
                    sock_client:send(data, {block = true})
                    count = count + 1
                else
                    break
                end
            end
            print("%s: recv: %d, count: %d", sock_client, result and result:size() or 0, count)
            if result then
                result:dump()
            end
            sock_client:close()
        end
    end
    sock:close()
end
