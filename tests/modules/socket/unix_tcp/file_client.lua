import("core.base.socket")
import("core.base.bytes")

function main(addr)
    addr = addr or path.join(os.tmpdir(), "file.socket")
    print("connect %s ..", addr)
    local sock = socket.connect_unix(addr)
    print("%s: connected!", sock)
    local real = 0
    local recv = 0
    local data = nil
    local wait = false
    local results = {}
    while true do
        real, data = sock:recv(8192)
        if real > 0 then
            recv = recv + real
            wait = false
            table.insert(results, data)
        elseif real == 0 and not wait then
            if sock:wait(socket.EV_RECV, -1) == socket.EV_RECV then
                wait = true
            else
                break
            end
        else
            break
        end
    end
    if #results > 0 then
        data = bytes(results)
    end
    print("%s: recv ok, size: %d, #data: %d!", sock, recv, data and data:size() or 0)
    sock:close()
end
