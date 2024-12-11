add_requires("linux-headers", {configs = {driver_modules = true}})

target("hello")
    add_rules("platform.linux.module")
    add_files("src/*.c")
    add_packages("linux-headers")
    set_license("GPL-2.0")
