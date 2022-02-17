set_languages("c++20")
target("A hello")
    set_kind("binary")
    add_files("src/*.cpp", "src/*.mpp")
