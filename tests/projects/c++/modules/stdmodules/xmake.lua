add_rules("mode.debug", "mode.release")
set_languages("c++latest")

target("mod")
    set_kind("static")
    add_files("src/*.cpp", "src/*.mpp")

target("stdmodules")
    set_kind("binary")
    add_files("test/*.cpp")
    add_deps("mod")
