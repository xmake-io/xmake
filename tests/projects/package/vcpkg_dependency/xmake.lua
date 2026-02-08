set_languages("c++17")
set_encodings("utf-8")

add_rules("mode.debug", "mode.release")

add_requires("vcpkg::openimageio[jpegxl,libraw,webp]", { configs = { shared = true } })
add_requires("vcpkg::boost-filesystem", { alias = "filesystem" })

target("test")
    set_kind("binary")
    add_files("src/*.cpp")
    add_packages("vcpkg::openimageio[jpegxl,libraw,webp]", "filesystem")
