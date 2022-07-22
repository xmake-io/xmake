import("core.base.fwatcher")

function main(watchdir)
    fwatcher.add(watchdir)
    while true do
        local ok, event = fwatcher.wait(-1)
        if ok > 0 then
            print(event)
        end
    end
end
