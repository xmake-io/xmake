set_languages("c++20")
target("hello")
    set_kind("binary")
    add_files("src/*.cpp", "src/*.mpp")
