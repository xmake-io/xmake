rule("utils.ispc")
    set_extensions(".ispc")

    on_load(function (target)
        local headersdir = path.join(target:autogendir(), "rules", "utils", "ispc", "headers")
        os.mkdir(headersdir)
        target:add("includedirs", headersdir, {public = true})
    end)
    
    before_buildcmd_file(function (target, batchcmds, sourcefile_ispc, opt)
        import("lib.detect.find_tool")
        local ispc = assert(find_tool("ispc"), "ispc not found!")

        local flags = {}
        if target:values("ispc.flags") then
            table.join2(flags, target:values("ispc.flags"))
        end

        if target:get("symbols") == "debug"  then
            table.insert(flags, "-g")
        end

        if target:get("optimize") == "none" then
            table.insert(flags, "-O0")
        elseif target:get("optimize") == "fast" then
            table.insert(flags, "-O2")
        elseif target:get("optimize") == "faster" or target:get("optimize") == "fastest" then
            table.insert(flags, "-O3")
        elseif target:get("optimize") == "smallest" then
            table.insert(flags, "-O1")
        end

        if target:get("warnings") == "none" then
            table.insert(flags, "--woff")
        elseif target:get("warnings") == "error" then
            table.insert(flags, "--werror")
        end

        if not target:is_plat("windows") then
            table.insert(flags, "--pic")
        end

        local headersdir = path.join(target:autogendir(), "rules", "utils", "ispc", "headers")
        local objectfile = target:objectfile(sourcefile_ispc)
        local objectdir = path.directory(objectfile)
        local headersfile
        local header_extension = target:extraconf("rules", "utils.ispc", "header_extension")
        if header_extension then
            headersfile = path.join(headersdir, path.basename(sourcefile_ispc) .. header_extension)
        else
            headersfile = path.join(headersdir, path.filename(sourcefile_ispc) .. ".h")
        end

        table.insert(flags, "-o")
        table.insert(flags, path(objectfile))
        table.insert(flags, "-h")
        table.insert(flags, path(headersfile))
        table.insert(flags, path(sourcefile_ispc))
        
        batchcmds:show_progress(opt.progress, "${color.build.object}compiling.ispc %s", sourcefile_ispc)
        batchcmds:mkdir(objectdir)
        batchcmds:vrunv(ispc.program, flags)

        table.insert(target:objectfiles(), objectfile)

        batchcmds:add_depfiles(sourcefile_ispc, headersfile)
        batchcmds:set_depmtime(os.mtime(objectfile))
        batchcmds:set_depcache(target:dependfile(objectfile))
    end)
