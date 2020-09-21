add_rules("mode.debug", "mode.release")
set_policy("build.across_targets_in_parallel", false)

target("merge_object")
    set_kind("static")
    add_files("src/interface.c")
    after_build_file(function (target, sourcefile)
        os.cp(target:objectfile(sourcefile), "$(buildir)/merge_object/")
    end)

target("test")
    set_kind("binary")
    add_deps("merge_object")
    add_files("src/test.c")
    if is_plat("windows") then
        add_files("$(buildir)/merge_object/interface.c.obj")
    else
        add_files("$(buildir)/merge_object/interface.c.o")
    end

