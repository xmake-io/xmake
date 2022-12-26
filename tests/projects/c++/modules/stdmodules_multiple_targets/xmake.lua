add_rules("mode.debug", "mode.release")

add_cxxflags("clang::-stdlib=libc++")

set_languages("c++latest")

target("mod")
    set_kind("static")
    add_files("src/*.cpp", "src/*.mpp")

target("mod2")
    set_kind("static")
    add_files("src/*.cpp", "src/*.mpp")
