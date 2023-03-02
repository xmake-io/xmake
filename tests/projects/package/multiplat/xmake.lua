add_rules("mode.debug", "mode.release")

add_requires("raylib")
add_requires("raylib~mingw", {plat = "mingw", arch = "x86_64"})

target("hello")
    add_packages("raylib")
    set_kind("binary")
    add_files("src/*.cpp")
    set_languages("c++11")

target("hello_mingw")
    set_plat("mingw")
    set_arch("x86_64")
    add_packages("raylib~mingw")
    set_kind("binary")
    add_files("src/*.cpp")

