add_requires("conan::zlib 1.2.11", {alias = "zlib", debug = true})
add_requires("conan::openssl 1.1.1g", {alias = "openssl",
    configs = {options = "OpenSSL:shared=True"}})

target("test")
    set_kind("binary")
    add_files("src/*.cpp")
    add_packages("openssl", "zlib")

