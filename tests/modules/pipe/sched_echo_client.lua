import("core.base.pipe")
import("core.base.scheduler")

function _session(id)
    local pipefile = pipe.open("test" .. id, 'w')
    local count = 0
    while count < 10000 do
        local write = pipefile:write("hello world..", {block = true})
        if write <= 0 then
            break
        end
        count = count + 1
    end
    print("%s/%d: write ok, count: %d!", pipefile, id, count)
    pipefile:close()
end

function main(count)
    count = count and tonumber(count) or 1
    for i = 1, count do
        scheduler.co_start(_session, i)
    end
end
