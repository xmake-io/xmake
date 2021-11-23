set_languages("c++20")

add_cxxflags("-fmodules-ts")

target("mod")
    set_kind("static")
    add_files("src/mod.mpp", "src/mod.cpp")

target("test")
    set_kind("binary")
    add_deps("mod")
    add_files("src/main.cpp")
