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
            local copydir = root .. "_copy"
            os.cp(root, copydir, {async = true})
            assert(os.isdir(copydir))
            os.rm(copydir, {async = true})
            print("async copy complete: %s", copydir)
        end)
    end)

    scheduler.co_group_wait(group)
    print("all async tasks finished")
    os.rm(root, {async = true})
    print("async scheduler test finished")
end

