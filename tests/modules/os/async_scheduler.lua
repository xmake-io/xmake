import("core.base.scheduler")

local function _prepare_workspace(root)
    os.mkdir(root)
    for idx = 1, 4 do
        io.writefile(path.join(root, string.format("file%d.txt", idx)), "xmake")
    end
end

function main()
    local root = os.tmpfile() .. ".os_async_sched"
    _prepare_workspace(root)
    print("workspace prepared: %s", root)

    local group = "os_async_scheduler"
    scheduler.co_group_begin(group, function ()
        for idx = 1, 4 do
            scheduler.co_start(function ()
                local matches = os.files(path.join(root, string.format("file%d.txt", idx)), {async = true})
                assert(matches and #matches == 1)
                print("async match %d finished", idx)
            end)
        end

        scheduler.co_start(function ()
            print("async find all files in programdir...")
            local files = os.files(path.join(os.programdir(), "**"), {async = true})
            print("files: %d", #files)
            print("async find all finished")
        end)
    end)
end
