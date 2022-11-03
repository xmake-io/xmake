add_rules("mode.debug", "mode.release")
set_languages("c++20")

add_cxxflags("-stdlib=libc++")
target("trouble")
    set_kind("shared")
    add_files("src/*.cpp", "src/*.mpp")

target("test")
    set_kind("binary")
    add_files("test/*.cpp")
    add_deps("trouble")
