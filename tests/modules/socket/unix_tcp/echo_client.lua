import("core.base.bytes")
import("core.base.socket")

function main(addr)
    addr = addr or path.join(os.tmpdir(), "echo.socket")
    print("connect %s ..", addr)
    local buff = bytes(8192)
    local sock = socket.connect_unix(addr)
    if sock then
        print("%s: connected!", sock)
        local count = 0
        while count < 10000 do
            local send = sock:send("hello world..", {block = true})
            if send > 0 then
                sock:recv(buff, 13, {block = true})
            else
                break
            end
            count = count + 1
        end
        print("%s: send ok, count: %d!", sock, count)
        sock:close()
    end
end
