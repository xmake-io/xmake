import("core.base.fwatcher")

function main(watchdir)
    print("watch %s ..", watchdir)
    fwatcher.on_modified(watchdir, function (filepath)
        print(filepath, "modified")
    end)
end
