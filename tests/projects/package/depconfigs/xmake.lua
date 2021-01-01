add_requires("libpng", {system = false, configs = {vs_runtime = "MD"},
                        after_load = function (package)
                            --package:set("deps", "zlib 1.2.10", {system = false, configs = {cxflags = "-DTEST"}})
                            package:extraconf_set("deps", "zlib", {system = false, configs = {cxflags = "-DTEST"}})
                        end})

add_requires("libtiff", {system = false, configs = {vs_runtime = "MD"},
                         deps = {system = false, configs = {cxflags = "-DTEST2"}}})

target("test")
    set_kind("binary")
    add_files("src/*.c")
    add_packages("libpng")

target("test2")
    set_kind("binary")
    add_files("src/*.c")
    add_packages("libtiff")
