import("core.base.fwatcher")

function main(watchdir)
    print("watch %s ..", watchdir)
    fwatcher.watchdirs(watchdir, function (event)
        local status
        if event.type == fwatcher.ET_CREATE then
            status = "created"
        elseif event.type == fwatcher.ET_MODIFY then
            status = "modified"
        elseif event.type == fwatcher.ET_DELETE then
            status = "deleted"
        end
        print(event.path, status)
    end)
end
