import("core.base.pipe")
import("core.base.bytes")
import("core.base.process")
import("core.base.scheduler")

function _session_read_pipe(id, rpipeopt)
    local results = {}
    local rpipe = rpipeopt.rpipe
    print("%s/%d: read ..", rpipe, id)
    while not rpipeopt.stop do
        local real, data = rpipe:read(8192)
        if real > 0 then
            table.insert(results, bytes(data, 1, real))
        elseif real == 0 then
            if rpipe:wait(pipe.EV_READ, -1) < 0 then
                break
            end
        else
            break
        end
    end
    results = bytes(results)
    print("%s/%d: read ok, size: %d", rpipe, id, results:size())
    if results:size() > 0 then
        results:dump()
    end
    rpipe:close()
end

function _session(id, program, ...)
    local rpipe, wpipe = pipe.openpair(10)
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
