add_rules("mode.debug", "mode.release")

add_requires("libpng", {system = false})

target("foo")
    set_kind("static")
    add_files("src/png.c")
    add_packages("libpng")
    set_policy("build.merge_archive", true)

target("test")
    add_files("src/main.c")
    add_deps("foo")
