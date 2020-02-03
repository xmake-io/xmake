import("core.base.scheduler")

function _session(id)
    print("test: %d ..", id)
    scheduler.co_yield()
    print("test: %d end", id)
end

function main()
    for i = 1, 10 do
        scheduler.co_start(_session, i)
    end
end

