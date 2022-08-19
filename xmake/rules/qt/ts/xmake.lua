rule("qt.ts")
    add_deps("qt.env")
    set_extensions(".ts")

    on_load(function (target)
        -- get lrelease
        local qt = assert(target:data("qt"), "qt not found!")
        local lrelease = path.join(qt.bindir, is_host("windows") and "lrelease.exe" or "lrelease")
        if not os.isexec(lrelease) and qt.libexecdir then
            lrelease = path.join(qt.libexecdir, is_host("windows") and "lrelease.exe" or "lrelease")
        end
        if not os.isexec(lrelease) and qt.libexecdir_host then
            lrelease = path.join(qt.libexecdir_host, is_host("windows") and "lrelease.exe" or "lrelease")
        end
        assert(os.isexec(lrelease), "lrelease not found!")

        -- save lrelease
        target:data_set("qt.ts", lrelease)
    end)

    on_buildcmd_file(function (target, batchcmds, sourcefile_ts, opt)
        -- get lrelease
        local lrelease = target:data("qt.ts")

        local outfile = path.join(target:targetdir(), path.basename(sourcefile_ts) .. ".qm")
        
        batchcmds:mkdir(target:targetdir())
        batchcmds:show_progress(opt.progress, "${color.build.object}compiling.qt.ts %s", sourcefile_ts)
        batchcmds:vrunv(lrelease, {path(sourcefile_ts), "-qm", outfile})

        batchcmds:add_depfiles(sourcefile_ts)
    end)
