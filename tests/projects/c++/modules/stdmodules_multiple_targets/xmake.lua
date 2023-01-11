add_rules("mode.debug", "mode.release")
set_languages("c++latest")

target("mod")
    set_kind("static")
    add_files("src/*.cpp", "src/*.mpp")

    set_policy("c++.clang.module.stdmodules", true)

target("mod2")
    set_kind("static")
    add_files("src/*.cpp", "src/*.mpp")

    set_policy("c++.clang.module.stdmodules", true)
