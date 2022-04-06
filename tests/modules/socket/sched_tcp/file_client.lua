import("core.base.socket")
import("core.base.scheduler")
import("core.base.bytes")

function _session(addr, port)
    print("connect %s:%d ..", addr, port)
    local sock = socket.connect(addr, port)
    print("%s: connected!", sock)
    local real = 0
    local recv = 0
    local data = nil
    local wait = false
    local buff = bytes(8192)
    while true do
        real, data = sock:recv(buff, 8192)
        if real > 0 then
            recv = recv + real
            wait = false
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
    print("%s: recv ok, size: %d!", sock, recv)
    sock:close()
end

function main(count)
    count = count and tonumber(count) or 1
    for i = 1, count do
        scheduler.co_start(_session, "127.0.0.1", 9092)
    end
end
