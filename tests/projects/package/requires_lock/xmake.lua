-- test requires lock functionality with zlib package
set_policy("package.requires_lock", true)

add_requires("zlib >=1.2.11", {system = false})
add_requires("zlib 1.2.13", {system = false, alias = "zlib_old"})  -- test lower version
add_requires("zlib", {system = false, configs = {shared = true}, alias = "zlib_shared"})

target("test_static")
    set_kind("binary")
    add_files("src/*.c")
    add_packages("zlib")

target("test_shared")
    set_kind("binary") 
    add_files("src/*.c")
    add_packages("zlib_shared")

target("test_old")
    set_kind("binary") 
    add_files("src/*.c")
    add_packages("zlib_old")
