add_rules("mode.debug", "mode.release")

add_moduledirs("modules")

rule("autogen")
    set_extensions(".in")
    before_build_file(function (target, sourcefile, opt)
        import("utils.progress")
        import("core.project.depend")
        import("core.tool.compiler")
        import("autogen.foo", {always_build = true})

        local sourcefile_cx = path.join(target:autogendir(), "rules", "autogen", path.basename(sourcefile) .. ".cpp")
        local objectfile = target:objectfile(sourcefile_cx)
        table.insert(target:objectfiles(), objectfile)

        depend.on_changed(function ()
            progress.show(opt.progress, "${color.build.object}compiling.autogen %s", sourcefile)
            os.mkdir(path.directory(sourcefile_cx))
            foo.generate(sourcefile, sourcefile_cx)
            compiler.compile(sourcefile_cx, objectfile, {target = target})
        end, {dependfile = target:dependfile(objectfile),
              files = sourcefile,
              changed = target:is_rebuilt()})
    end)

target("test")
    set_kind("binary")
    add_rules("autogen")
    add_files("src/main.cpp")
    add_files("src/*.in")

