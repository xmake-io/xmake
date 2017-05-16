set_default(false)
set_languages("c99")
set_kind("binary")
add_deps("sv")
add_links("sv")
add_includedirs("../include")
add_linkdirs("$(buildir)")

target("semver_test")
    add_files("semver.c")

target("comp_test")
    add_files("comp.c")

target("range_test")
    add_files("range.c")

target("match_test")
    add_files("match.c")

task("check")
    on_run(function ()
        import("core.project.task")
        task.run("run", {target = "semver_test"})
        task.run("run", {target = "comp_test"})
        task.run("run", {target = "range_test"})
        task.run("run", {target = "match_test"})
    end)
    set_menu {
        usage = "xmake check"
    ,   description = "Run tests !"
    ,   options = {}
    }
