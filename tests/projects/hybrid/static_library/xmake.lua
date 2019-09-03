add_rules("mode.release", "mode.debug")

target("test")
    set_kind("static")
    add_files("src/*.c", "src/*.cpp")
    add_files("src/*.m", "src/*.mm") 

target("demo")
    set_kind("binary")
    add_deps("test")
    add_files("src/main.cpp") 

target("demo2")
    set_kind("binary")
    add_files("src/main2.cpp", "src/*.d") 


