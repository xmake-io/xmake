import("core.base.fwatcher")
import("core.base.scheduler")

function _watch(watchdir)
    print("watch %s ..", watchdir)
    fwatcher.add(watchdir)
    while true do
        local ok, event = fwatcher.wait(-1)
        if ok > 0 then
            print(event)
        end
    end
end

function _sleep()
    while true do
        print("sleep ..")
        os.sleep(1000)
    end
end

function main(watchdir)
    scheduler.co_start(_watch, watchdir)
    scheduler.co_start(_sleep)
end
