import("core.base.process")
import("core.base.scheduler")

function _session(id, program, ...)
    local proc = process.openv(program, table.pack(...))
    local ok, status = proc:wait(-1)
    print("%s/%d: %d, status: %d", proc, id, ok, status)
    proc:close()
end

function main(program, ...)
    for i = 1, 10 do
        scheduler.co_start(_session, i, program, ...)
    end
end
