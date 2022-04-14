import("core.base.pipe")
import("core.base.bytes")
import("core.base.process")
import("core.base.scheduler")

function _session_read_pipe(id, rpipeopt)
    local buff = bytes(8192)
    local rpipe = rpipeopt.rpipe
    print("%s/%d: read ..", rpipe, id)
    local read = 0
    while not rpipeopt.stop do
        local real, data = rpipe:read(buff, 8192 - read, {start = read + 1})
        if real > 0 then
            read = read + real
        elseif real == 0 then
            if rpipe:wait(pipe.EV_READ, -1) < 0 then
                break
            end
        else
            break
        end
    end
    local results = bytes(buff, 1, read)
    print("%s/%d: read ok, size: %d", rpipe, id, results:size())
    if results:size() > 0 then
        results:dump()
    end
    rpipe:close()
end

function _session(id, program, ...)
    local rpipe, wpipe = pipe.openpair()
    local rpipeopt = {rpipe = rpipe, stop = false}
    scheduler.co_start(_session_read_pipe, id, rpipeopt)
    local proc = process.openv(program, table.pack(...), {stdout = wpipe})
    local ok, status = proc:wait(-1)
    rpipeopt.stop = true
    print("%s/%d: %d, status: %d", proc, id, ok, status)
    proc:close()
    wpipe:close()
end

function main(program, ...)
    for i = 1, 10 do
        scheduler.co_start(_session, i, program, ...)
    end
end
