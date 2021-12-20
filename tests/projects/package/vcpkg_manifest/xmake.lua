--add_requires("vcpkg::zlib 1.2.11", "vcpkg::fmt >=8.0.1")
add_requires("vcpkg::arrow", {configs = {features = {"json"}}})

target("test")
    set_kind("binary")
    add_files("src/*.cpp")
    add_packages("vcpkg::zlib", "vcpkg::fmt", "vcpkg::arrow")

