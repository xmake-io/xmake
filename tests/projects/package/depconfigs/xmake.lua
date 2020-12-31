add_requires("libpng", {system = false, configs = {vs_runtime = "MD"}, depconfigs = {cxflags = "-DTEST"}})

target("test")
    set_kind("binary")
    add_files("src/*.c")
    add_packages("libpng")
