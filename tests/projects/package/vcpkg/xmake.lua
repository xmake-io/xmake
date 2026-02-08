add_rules("mode.debug", "mode.release")

add_requires("vcpkg::zlib", "vcpkg::pcre2")
add_requires("vcpkg::boost[core]", {alias = "boost"})

target("test")
    set_kind("binary")
    add_files("src/*.cpp")
    add_packages("vcpkg::zlib", "vcpkg::pcre2", "boost")

