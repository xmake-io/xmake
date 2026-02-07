set_languages("c++17")
set_encodings("utf-8")

add_requires("vcpkg::openimageio", { configs = { shared = true } })
add_requires("vcpkg::openssl[ssl3]", { configs = { shared = true } })

target("test")
    set_kind("binary")
    add_files("src/*.cpp")
    add_packages("vcpkg::openimageio", "vcpkg::openssl[ssl3]")