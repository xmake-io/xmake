package("myzlib")
    set_base("zlib")
    set_urls("https://github.com/madler/zlib.git")
package_end()

add_requires("myzlib", {system = false, alias = "zlib"})

target("test")
    set_kind("binary")
    add_files("src/*.c")
    add_packages("zlib")
