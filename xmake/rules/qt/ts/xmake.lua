rule("qt.ts")
    add_deps("qt.env")
    set_extensions(".ts")

    on_config(function (target)
        -- get source file
        local lupdate_argv = {"-no-obsolete"}
        local sourcefile_ts
        for _, sourcebatch in pairs(target:sourcebatches()) do
            if sourcebatch.rulename == "qt.ts" then
                sourcefile_ts = sourcebatch.sourcefiles[1]
            else
                if sourcebatch.sourcefiles then
                    for _, sourcefile in ipairs(sourcebatch.sourcefiles) do
                        table.join2(lupdate_argv, path(sourcefile))
                    end
                end
            end
        end
        if sourcefile_ts then
            -- get lupdate and lrelease
            local qt = assert(target:data("qt"), "qt not found!")
            local lupdate = path.join(qt.bindir, is_host("windows") and "lupdate.exe" or "lupdate")
            local lrelease = path.join(qt.bindir, is_host("windows") and "lrelease.exe" or "lrelease")
            if not os.isexec(lupdate) and qt.libexecdir then
                lupdate = path.join(qt.libexecdir, is_host("windows") and "lupdate.exe" or "lupdate")
            end
            if not os.isexec(lrelease) and qt.libexecdir then
                lrelease = path.join(qt.libexecdir, is_host("windows") and "lrelease.exe" or "lrelease")
            end
            if not os.isexec(lupdate) and qt.libexecdir_host then
                lupdate = path.join(qt.libexecdir_host, is_host("windows") and "lupdate.exe" or "lupdate")
            end
            if not os.isexec(lrelease) and qt.libexecdir_host then
                lrelease = path.join(qt.libexecdir_host, is_host("windows") and "lrelease.exe" or "lrelease")
            end
            assert(os.isexec(lupdate), "lupdate not found!")
            assert(os.isexec(lrelease), "lrelease not found!")
            table.join2(lupdate_argv, {"-ts", path(sourcefile_ts)})
            os.vrunv(lupdate, lupdate_argv)
            -- save lrelease
            target:data_set("qt.ts.lrelease", lrelease)
        end
    end)

    before_buildcmd_file(function (target, batchcmds, sourcefile_ts, opt)
        -- get lrelease
        local lrelease = target:data("qt.ts.lrelease")
        local outfile = path.join(target:targetdir(), path.basename(sourcefile_ts) .. ".qm")
        batchcmds:mkdir(target:targetdir())
        batchcmds:show_progress(opt.progress, "${color.build.object}compiling.qt.ts %s", sourcefile_ts)
        batchcmds:vrunv(lrelease, {path(sourcefile_ts), "-qm", path(outfile)})
        batchcmds:add_depfiles(sourcefile_ts)
    end)