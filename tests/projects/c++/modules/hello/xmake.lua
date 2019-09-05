target("hello")
    set_kind("binary")
    add_rules("c++.build.modules")
    add_files("src/*.cpp", "src/*.mpp") 


