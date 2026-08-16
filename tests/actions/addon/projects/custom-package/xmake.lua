-- the package definitions come from the addon
includes("@addon/custom-package/packages")

add_requires("hello-utils")

target("test")
    set_kind("binary")
    add_files("src/main.c")
    add_packages("hello-utils")
