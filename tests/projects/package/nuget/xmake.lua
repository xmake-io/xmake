add_requires("nuget::zlib_static", {alias = "zlib"})

target("test")
    set_kind("binary")
    add_files("src/*.cpp")
    add_packages("zlib")

