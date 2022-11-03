rule("utils.ispc")
    set_extensions(".ispc")
    add_deps("utils.inherit.links")

    on_load(function (target)
        local header_outputdir = path.join(target:autogendir(), "ispc_headers")
        local obj_outputdir = path.join(target:autogendir(), "ispc_objs")
        os.mkdir(target:autogendir())
        os.mkdir(header_outputdir)
        os.mkdir(obj_outputdir)
        target:add("includedirs", header_outputdir, {public = true})
    end)
    before_buildcmd_file(function (target, batchcmds, sourcefile_ispc, opt)
        import("lib.detect.find_tool")
        ispc = find_tool("ispc")
        assert(ispc, "ispc not found!")

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

        local obj_extension = ".o"
        if target:is_plat("windows") then
            obj_extension = ".obj"
        end

        local header_outputdir = path.join(target:autogendir(), "ispc_headers")
        local obj_outputdir = path.join(target:autogendir(), "ispc_objs")
        local obj_file = path.join(obj_outputdir, path.filename(sourcefile_ispc) .. obj_extension)

        local header_file
        local header_extension = target:extraconf("rules", "utils.ispc", "header_extension")
        if header_extension then
            header_file = path.join(header_outputdir, path.basename(sourcefile_ispc) .. header_extension)
        else
            header_file = path.join(header_outputdir, path.filename(sourcefile_ispc) .. ".h")
        end

        batchcmds:show_progress(opt.progress, "${color.build.object}cache compiling %s", sourcefile_ispc)
        batchcmds:vrunv(ispc.program, table.join2(flags,
            {"-o", obj_file,
            "-h", header_file,
            path.join(os.projectdir(), sourcefile_ispc)}))

        table.insert(target:objectfiles(), obj_file)

        batchcmds:add_depfiles(sourcefile_ispc)
        batchcmds:set_depmtime(os.mtime(obj_file))
        batchcmds:set_depcache(target:dependfile(obj_file))
        batchcmds:set_depmtime(os.mtime(header_file))
        batchcmds:set_depcache(target:dependfile(header_file))
    end)