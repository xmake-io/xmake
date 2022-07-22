import("core.base.fwatcher")

function main(watchdir)
    print("watch %s ..", watchdir)
    fwatcher.on_created(watchdir, function (filepath)
        print(filepath, "created")
    end)
end
