import("core.base.pipe")
import("core.base.scheduler")

function _session(id)

    local pipefile = pipe.open("test" .. id, 'r')
    if pipefile:connect() > 0 then
        print("%s/%d: connected", pipefile, id)
        local count = 0
        local result = nil
        while count < 10000 do
            local read, data = pipefile:read(13, {block = true})
            if read > 0 then
                result = data
                count = count + 1
            else
                break
            end
        end
        print("%s/%d: read: %d, count: %d", pipefile, id, result and result:size() or 0, count)
        result:dump()
    end
    pipefile:close()
end

function main(count)
    count = count and tonumber(count) or 1
    for i = 1, count do
        scheduler.co_start(_session, i)
    end
end
