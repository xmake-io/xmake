set_languages("c++20")

target("mod")
    set_kind("static")
    add_modulefiles("src/mod.mpp", "src/mod.cpp")

target("test")
    set_kind("binary")
    add_deps("mod")
    add_files("src/main.cpp")
