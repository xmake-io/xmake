import("core.base.fwatcher")

function main(watchdir)
    print("watch %s ..", watchdir)
    fwatcher.watchdirs(watchdir, function (event)
        print(event)
    end)
end
