add_rules("mode.debug", "mode.release")
set_languages("c++20")

add_cxxflags("clang::-stdlib=libc++")
set_values("msvc.modules.stdifcdir", true)
target("mod")
    set_kind("shared")
    add_files("src/*.cpp", "src/*.mpp")

target("test")
    set_kind("binary")
    add_files("test/*.cpp")
    add_deps("mod")
