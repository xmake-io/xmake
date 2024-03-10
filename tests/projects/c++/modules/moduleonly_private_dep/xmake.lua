set_languages("c++20")

target("A")
    set_kind("moduleonly")
    add_files("src/modA.mpp")

target("B")
    add_deps("A")
    set_kind("static")
    add_files("src/modB.mpp", { public = true })
    add_files("src/modB.cpp")

target("test")
    set_kind("binary")
    add_deps("B")
    add_files("src/main.cpp")

