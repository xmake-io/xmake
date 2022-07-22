import("core.base.fwatcher")

function main(watchdir)
    print("watch %s ..", watchdir)
    fwatcher.on_deleted(watchdir, function (filepath)
        print(filepath, "deleted")
    end)
end
