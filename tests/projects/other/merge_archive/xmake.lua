add_rules("mode.debug", "mode.release")

target("add")
    set_kind("static")
    add_files("src/add.c")
    set_targetdir("$(buildir)/merge_archive")

target("sub")
    set_kind("static")
    add_files("src/sub.c")
    set_targetdir("$(buildir)/merge_archive")

target("mul")
    set_kind("static")
    add_deps("add", "sub")
    add_files("src/mul.c")
    set_policy("build.across_targets_in_parallel", false)
    if is_plat("windows") then
        add_files("$(buildir)/merge_archive/*.lib")
    else
        add_files("$(buildir)/merge_archive/*.a")
    end

