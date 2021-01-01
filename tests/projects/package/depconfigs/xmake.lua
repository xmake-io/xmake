add_requires("libpng", "libtiff", {system = false, configs = {vs_runtime = "MD"}})
add_requires("libwebp")

add_requireconfs("libwebp",      {system = false, configs = {shared = true, vs_runtime = "MD"}})
add_requireconfs("libpng.zlib",  {system = false, configs = {cxflags = "-DTEST1"}, version = "1.2.10"})
add_requireconfs("libtiff.*",    {system = false, configs = {cxflags = "-DTEST2"}})
add_requireconfs("libwebp.**",   {system = false, configs = {cxflags = "-DTEST3"}})

target("test")
    set_kind("binary")
    add_files("src/*.c")
    add_packages("libpng")

target("test2")
    set_kind("binary")
    add_files("src/*.c")
    add_packages("libtiff")

target("test3")
    set_kind("binary")
    add_files("src/*.c")
    add_packages("libwebp")

