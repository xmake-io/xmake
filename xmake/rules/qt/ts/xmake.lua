rule("qt.ts")
    add_deps("qt.env")
    set_extensions(".ts")

    on_config(function (target)
        -- get lrelease
        local qt = assert(target:data("qt"), "qt not found!")
        local lupdate = path.join(qt.bindir, is_host("windows") and "lupdate.exe" or "lupdate")
        if not os.isexec(lupdate) and qt.libexecdir then
            lupdate = path.join(qt.libexecdir, is_host("windows") and "lupdate.exe" or "lupdate")
        end
        if not os.isexec(lupdate) and qt.libexecdir_host then
            lupdate = path.join(qt.libexecdir_host, is_host("windows") and "lupdate.exe" or "lupdate")
        end
        assert(os.isexec(lupdate), "lupdate not found!")
        local lrelease = path.join(qt.bindir, is_host("windows") and "lrelease.exe" or "lrelease")
        if not os.isexec(lrelease) and qt.libexecdir then
            lrelease = path.join(qt.libexecdir, is_host("windows") and "lrelease.exe" or "lrelease")
        end
        if not os.isexec(lrelease) and qt.libexecdir_host then
            lrelease = path.join(qt.libexecdir_host, is_host("windows") and "lrelease.exe" or "lrelease")
        end
        assert(os.isexec(lrelease), "lrelease not found!")
        -- save lupdate and lrelease
        target:data_set("qt.ts.lupdate", lupdate)
        target:data_set("qt.ts.lrelease", lrelease)
    end)

    before_buildcmd_file(function (target, batchcmds, sourcefile_ts, opt)
        -- get lupdate and lrelease
        local lupdate = target:data("qt.ts.lupdate")
        local lrelease = target:data("qt.ts.lrelease")
        -- get source file
        local lupdate_argv = {"-no-obsolete"}
        for _, sourcebatch in pairs(target:sourcebatches()) do
            local sourcefiles = sourcebatch.sourcefiles
            if sourcefiles then
                for _, sourcefile in ipairs(sourcebatch.sourcefiles) do
                    table.join2(lupdate_argv, path(sourcefile))
                end
            end
        end
        table.join2(lupdate_argv, {"-ts", path(sourcefile_ts)})
        local outfile = path.join(target:targetdir(), path.basename(sourcefile_ts) .. ".qm")
        batchcmds:mkdir(target:targetdir())
        batchcmds:show_progress(opt.progress, "${color.build.object}compiling.qt.ts %s", sourcefile_ts)
        batchcmds:vrunv(lupdate, lupdate_argv)
        batchcmds:vrunv(lrelease, {path(sourcefile_ts), "-qm", path(outfile)})
        batchcmds:add_depfiles(sourcefile_ts)
    end)