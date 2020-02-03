import("core.base.pipe")
import("core.base.scheduler")

function _session_read(id, pipefile)
    print("%s/%d: read ..", pipefile, id)
    local result = nil
    for i = 1, 10000 do
        local read, data = pipefile:read(12, {block = true})
        if read > 0 and data then
            result = data:str()
        end
    end
    print("%s/%d: read ok, data: %s", pipefile, id, result and result or "")
    pipefile:close()
end

function _session_write(id, pipefile)
    print("%s/%d: write ..", pipefile, id)
    for i = 1, 10000 do
        pipefile:write("hello xmake!", {block = true})
    end
    print("%s/%d: write ok", pipefile, id)
    pipefile:close()
end

function _session(id)
    local rpipe, wpipe = pipe.openpair(256)
    scheduler.co_start(_session_read, id, rpipe)
    scheduler.co_start(_session_write, id, wpipe)
end

function main(count)
    count = count and tonumber(count) or 1
    for i = 1, count do
        scheduler.co_start(_session, i)
    end
end
